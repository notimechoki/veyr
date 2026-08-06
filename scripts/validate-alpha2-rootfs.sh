#!/usr/bin/env bash

set -Eeuo pipefail

VALIDATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${VALIDATE_DIR}/.." && pwd)"

export VEYR_ROOT="${ROOT_DIR}"

source "${ROOT_DIR}/scripts/lib/common.sh"
source "${ROOT_DIR}/scripts/lib/toolchain.sh"

ROOTFS="${1:-${ROOT_DIR}/build/images/base-alpha2/rootfs}"

[[ -d "${ROOTFS}" ]] \
    || die "Alpha.2 rootfs does not exist: ${ROOTFS}"

BUSYBOX="${ROOTFS}/usr/libexec/busybox"
LOADER="${ROOTFS}/lib64/ld-linux-x86-64.so.2"
LDCONFIG="${ROOTFS}/usr/sbin/ldconfig"
CACHE="${ROOTFS}/etc/ld.so.cache"

EXPECTED_INTERPRETER="/lib64/ld-linux-x86-64.so.2"

[[ -x "${BUSYBOX}" ]] \
    || die "Static rescue BusyBox is missing: ${BUSYBOX}"

BUSYBOX_INFO="$(file "${BUSYBOX}")"

printf '[ROOTFS-CHECK] BusyBox: %s\n' \
    "${BUSYBOX_INFO}"

if ! grep -qi 'statically linked' <<<"${BUSYBOX_INFO}"; then
    die "Rescue BusyBox is not statically linked"
fi

[[ -f "${LOADER}" ]] \
    || die "Dynamic loader is not a real file: ${LOADER}"

[[ ! -L "${LOADER}" ]] \
    || die "Dynamic loader in /lib64 must not be a symlink"

[[ -x "${LOADER}" ]] \
    || die "Dynamic loader is not executable: ${LOADER}"

printf '[ROOTFS-CHECK] Loader: %s\n' \
    "$(file "${LOADER}")"

[[ -x "${LDCONFIG}" ]] \
    || die "Veyr ldconfig is missing: ${LDCONFIG}"

LDCONFIG_INFO="$(file "${LDCONFIG}")"

printf '[ROOTFS-CHECK] ldconfig: %s\n' \
    "${LDCONFIG_INFO}"

if ! grep -Eqi 'static|statically linked' <<<"${LDCONFIG_INFO}"; then
    die "Veyr ldconfig is not static"
fi

[[ -s "${CACHE}" ]] \
    || die "/etc/ld.so.cache is missing or empty"

[[ -f "${ROOTFS}/etc/ld.so.conf" ]] \
    || die "/etc/ld.so.conf is missing"

grep -qx '/usr/lib' "${ROOTFS}/etc/ld.so.conf" \
    || die "/usr/lib is not configured in /etc/ld.so.conf"

require_cross_tool readelf

check_library() {
    local soname="$1"
    local path="${ROOTFS}/usr/lib/${soname}"
    local resolved

    [[ -e "${path}" ]] \
        || die "Required runtime library is missing: /usr/lib/${soname}"

    resolved="$(readlink -f "${path}")"

    [[ -n "${resolved}" && -e "${resolved}" ]] \
        || die "Broken runtime library link: /usr/lib/${soname}"

    case "${resolved}" in
        "${ROOTFS}"/*)
            ;;
        *)
            die "Runtime library escapes rootfs: /usr/lib/${soname} -> ${resolved}"
            ;;
    esac

    printf '[ROOTFS-CHECK] Library OK: /usr/lib/%s\n' \
        "${soname}"
}

RUNTIME_LIBRARIES=(
    libc.so.6
    libm.so.6
    libncursesw.so.6
    libstdc++.so.6
    libgcc_s.so.1
)

for library in "${RUNTIME_LIBRARIES[@]}"; do
    check_library "${library}"
done

CACHE_LISTING="$(
    "${LDCONFIG}" \
        -r "${ROOTFS}" \
        -p
)"

for library in "${RUNTIME_LIBRARIES[@]}"; do
    if ! grep -Fq "${library}" <<<"${CACHE_LISTING}"; then
        printf '%s\n' "${CACHE_LISTING}" >&2
        die "Dynamic loader cache does not contain ${library}"
    fi

    printf '[ROOTFS-CHECK] Cache OK: %s\n' \
        "${library}"
done

check_dynamic_binary() {
    local relative="$1"
    local binary="${ROOTFS}/${relative}"
    local interpreter

    [[ -x "${binary}" ]] \
        || die "Required alpha.2 executable is missing: /${relative}"

    interpreter="$(
        "${VEYR_TARGET}-readelf" \
            -l "${binary}" 2>/dev/null \
        | sed -n \
            's@.*Requesting program interpreter: \(.*\)]@\1@p'
    )"

    [[ -n "${interpreter}" ]] \
        || die "Unable to determine ELF interpreter for /${relative}"

    [[ "${interpreter}" == "${EXPECTED_INTERPRETER}" ]] \
        || die "Unexpected ELF interpreter for /${relative}: ${interpreter}"

    printf '[ROOTFS-CHECK] ELF OK: /%s -> %s\n' \
        "${relative}" \
        "${interpreter}"
}

KEY_BINARIES=(
    usr/bin/bash
    usr/bin/ls
    usr/bin/uname
    usr/bin/cat
    usr/bin/make
    usr/bin/file
    usr/bin/gcc
    usr/bin/g++
)

for binary in "${KEY_BINARIES[@]}"; do
    check_dynamic_binary "${binary}"
done

[[ -x "${ROOTFS}/usr/lib/veyr-tests/userspace-smoke.sh" ]] \
    || die "Runtime userspace smoke test is missing from rootfs"

[[ -L "${ROOTFS}/bin" \
    && "$(readlink "${ROOTFS}/bin")" == "usr/bin" ]] \
    || die "/bin does not point to usr/bin"

[[ -L "${ROOTFS}/lib" \
    && "$(readlink "${ROOTFS}/lib")" == "usr/lib" ]] \
    || die "/lib does not point to usr/lib"

[[ -L "${ROOTFS}/sbin" \
    && "$(readlink "${ROOTFS}/sbin")" == "usr/sbin" ]] \
    || die "/sbin does not point to usr/sbin"

success "Alpha.2 rootfs structure and loader cache validation passed"