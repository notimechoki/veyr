#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export VEYR_ROOT="${ROOT_DIR}"

source "${ROOT_DIR}/scripts/lib/common.sh"
source "${ROOT_DIR}/scripts/lib/toolchain.sh"

ROOTFS_INPUT="${1:-${ROOT_DIR}/build/images/base-alpha4/rootfs}"

[[ -d "${ROOTFS_INPUT}" ]] \
    || die "Alpha.4 rootfs does not exist: ${ROOTFS_INPUT}"

# Canonicalize the rootfs path before any containment checks. The validator is
# commonly invoked with a repository-relative path (build/images/...), while
# readlink -f returns absolute paths. Comparing an absolute resolved executable
# against a relative ROOTFS makes every valid file look as if it escaped the
# rootfs.
ROOTFS="$(cd "${ROOTFS_INPUT}" && pwd -P)"

LOADER="${ROOTFS}/lib64/ld-linux-x86-64.so.2"
BUSYBOX="${ROOTFS}/usr/libexec/busybox"
LDCONFIG="${ROOTFS}/usr/sbin/ldconfig"
EXPECTED_INTERPRETER=/lib64/ld-linux-x86-64.so.2
LIBRARY_PATH="${ROOTFS}/usr/lib:${ROOTFS}/lib"
TARGET=x86_64-veyr-linux-gnu

[[ -f "${LOADER}" && ! -L "${LOADER}" && -x "${LOADER}" ]] \
    || die "Alpha.4 ELF loader is missing or invalid"
[[ -x "${BUSYBOX}" ]] || die "Alpha.4 static BusyBox is missing"
[[ -x "${LDCONFIG}" ]] || die "Alpha.4 ldconfig is missing"
[[ -x "${ROOTFS}/sbin/init" ]] || die "Alpha.4 /sbin/init is missing"
[[ -x "${ROOTFS}/usr/lib/veyr-tests/native-alpha4-smoke.sh" ]] \
    || die "Alpha.4 runtime smoke test is missing"
[[ -s "${ROOTFS}/etc/ld.so.cache" ]] || die "Alpha.4 loader cache is missing"
[[ "$(cat "${ROOTFS}/etc/veyr-stage" 2>/dev/null || true)" == "alpha4-native-complete" ]] \
    || die "Alpha.4 completion marker is missing"

if ! file "${BUSYBOX}" | grep -qi 'statically linked'; then
    die "Alpha.4 BusyBox is not static"
fi

require_cross_tool readelf

resolve_inside_rootfs() {
    local path="$1"
    local resolved

    resolved="$(readlink -f "${path}" 2>/dev/null || true)"

    [[ -n "${resolved}" && -e "${resolved}" ]] \
        || die "Unable to resolve alpha.4 path: ${path#${ROOTFS}}"

    case "${resolved}" in
        "${ROOTFS}"/*) ;;
        *) die "Resolved path escapes alpha.4 rootfs: ${path#${ROOTFS}} -> ${resolved}" ;;
    esac

    printf '%s\n' "${resolved}"
}

check_elf_binary() {
    local relative="$1"
    local binary="${ROOTFS}/${relative}"
    local resolved
    local interpreter
    local listing
    local file_info

    [[ -x "${binary}" ]] || die "Missing alpha.4 executable: /${relative}"

    resolved="$(resolve_inside_rootfs "${binary}")"
    file_info="$(file -L "${binary}")"

    if ! grep -q 'ELF ' <<<"${file_info}"; then
        die "Expected ELF executable at /${relative}, got: ${file_info}"
    fi

    interpreter="$(
        { "${VEYR_TARGET}-readelf" -l "${resolved}" 2>/dev/null || true; } \
            | sed -n 's@.*Requesting program interpreter: \(.*\)]@\1@p'
    )"

    [[ "${interpreter}" == "${EXPECTED_INTERPRETER}" ]] \
        || die "Unexpected interpreter for /${relative}: ${interpreter:-<missing>}"

    if ! listing="$(
        "${LOADER}" \
            --library-path "${LIBRARY_PATH}" \
            --list "${resolved}" 2>&1
    )"; then
        printf '%s\n' "${listing}" >&2
        die "Unable to resolve runtime libraries for /${relative}"
    fi

    if grep -q 'not found' <<<"${listing}"; then
        printf '%s\n' "${listing}" >&2
        die "Unresolved runtime library for /${relative}"
    fi

    if [[ -L "${binary}" ]]; then
        printf '[ALPHA4-ROOTFS] ELF OK: /%s -> %s\n' \
            "${relative}" "${resolved#${ROOTFS}/}"
    else
        printf '[ALPHA4-ROOTFS] ELF OK: /%s\n' "${relative}"
    fi
}

check_script() {
    local relative="$1"
    local script_path="${ROOTFS}/${relative}"
    local resolved
    local shebang
    local interpreter_spec
    local interpreter

    [[ -x "${script_path}" ]] || die "Missing alpha.4 script: /${relative}"

    resolved="$(resolve_inside_rootfs "${script_path}")"
    shebang="$(head -n 1 "${resolved}" 2>/dev/null || true)"

    [[ "${shebang}" == '#!'* ]] \
        || die "Executable /${relative} is neither ELF nor a shebang script"

    interpreter_spec="${shebang#\#!}"
    interpreter_spec="${interpreter_spec#${interpreter_spec%%[![:space:]]*}}"
    interpreter="${interpreter_spec%%[[:space:]]*}"

    case "${interpreter}" in
        /usr/bin/perl)
            [[ -x "${ROOTFS}/usr/bin/perl" ]] \
                || die "/${relative} requires /usr/bin/perl, but Perl is missing"
            ;;
        /usr/bin/bash)
            [[ -x "${ROOTFS}/usr/bin/bash" ]] \
                || die "/${relative} requires /usr/bin/bash, but Bash is missing"
            ;;
        /bin/sh)
            [[ -x "${ROOTFS}/bin/sh" ]] \
                || die "/${relative} requires /bin/sh, but it is missing"
            ;;
        /usr/bin/env)
            # Some upstream scripts use /usr/bin/env. env itself must be Veyr's.
            [[ -x "${ROOTFS}/usr/bin/env" ]] \
                || die "/${relative} requires /usr/bin/env, but it is missing"
            ;;
        *)
            die "Unexpected script interpreter for /${relative}: ${shebang}"
            ;;
    esac

    if [[ -L "${script_path}" ]]; then
        printf '[ALPHA4-ROOTFS] SCRIPT OK: /%s -> %s (%s)\n' \
            "${relative}" "${resolved#${ROOTFS}/}" "${shebang}"
    else
        printf '[ALPHA4-ROOTFS] SCRIPT OK: /%s (%s)\n' \
            "${relative}" "${shebang}"
    fi
}

check_executable() {
    local relative="$1"
    local path="${ROOTFS}/${relative}"
    local resolved
    local file_info

    [[ -x "${path}" ]] || die "Missing alpha.4 executable: /${relative}"

    resolved="$(resolve_inside_rootfs "${path}")"
    file_info="$(file -L "${path}")"

    if grep -q 'ELF ' <<<"${file_info}"; then
        check_elf_binary "${relative}"
        return
    fi

    if head -n 1 "${resolved}" 2>/dev/null | grep -q '^#!'; then
        check_script "${relative}"
        return
    fi

    die "Unsupported executable type at /${relative}: ${file_info}"
}

# Validate the actual installed executable type instead of assuming every
# command is a regular ELF file. Python commonly installs /usr/bin/python3 as
# a symlink to python3.X, while Texinfo installs makeinfo as a Perl program.
for executable in \
    usr/bin/bash \
    usr/bin/gcc \
    usr/bin/g++ \
    usr/bin/msgfmt \
    usr/bin/bison \
    usr/bin/perl \
    usr/bin/python3 \
    usr/bin/makeinfo \
    usr/bin/lsblk \
    usr/bin/mount; do

    check_executable "${executable}"
done

for path in \
    usr/include/zlib.h \
    usr/include/mpdecimal.h \
    usr/lib/libz.so.1 \
    usr/lib/libmpdec.so.4 \
    usr/lib/libpython3.14.so.1.0; do

    [[ -e "${ROOTFS}/${path}" ]] \
        || die "Missing alpha.4 library/development output: /${path}"

    printf '[ALPHA4-ROOTFS] File OK: /%s\n' "${path}"
done

for package in \
    gettext-native \
    bison-native \
    perl-native \
    zlib-native \
    mpdecimal-native \
    python-native \
    texinfo-native \
    util-linux-native; do

    marker="${ROOTFS}/usr/lib/veyr/native-build/${package}.stamp"

    [[ -f "${marker}" ]] || die "Missing native-build marker: ${package}"

    grep -qx 'environment=chroot' "${marker}" \
        || die "Invalid build environment marker for ${package}"

    grep -qx "compiler=${TARGET}" "${marker}" \
        || die "Invalid compiler marker for ${package}"

    printf '[ALPHA4-ROOTFS] Native marker OK: %s\n' "${package}"
done

CACHE_LISTING="$("${LDCONFIG}" -r "${ROOTFS}" -p)"

for soname in \
    libc.so.6 \
    libm.so.6 \
    libncursesw.so.6 \
    libstdc++.so.6 \
    libgcc_s.so.1 \
    libz.so.1 \
    libmpdec.so.4 \
    libpython3.14.so.1.0; do

    grep -Fq "${soname}" <<<"${CACHE_LISTING}" \
        || die "Alpha.4 loader cache does not contain ${soname}"

    printf '[ALPHA4-ROOTFS] Cache OK: %s\n' "${soname}"
done

success "Alpha.4 native rootfs validation passed"
