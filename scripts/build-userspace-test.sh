#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

export VEYR_ROOT="${ROOT_DIR}"

source "${ROOT_DIR}/scripts/lib/common.sh"
source "${ROOT_DIR}/scripts/lib/toolchain.sh"

EXPECTED_INTERPRETER="/lib64/ld-linux-x86-64.so.2"

SYSROOT_LOADER="${VEYR_SYSROOT}/usr/lib/ld-linux-x86-64.so.2"
SYSROOT_INTERPRETER="${VEYR_SYSROOT}${EXPECTED_INTERPRETER}"

LIBRARY_PATH="${VEYR_SYSROOT}/usr/lib:${VEYR_SYSROOT}/lib"

REQUIRED_FILES=(
    usr/bin/bash
    usr/bin/sh
    usr/bin/m4
    usr/bin/tic
    usr/bin/ls
    usr/bin/uname
    usr/bin/cat
    usr/bin/head
    usr/bin/sort
    usr/bin/uniq
    usr/bin/rm
    usr/bin/mkdir
    usr/bin/diff
    usr/bin/file
    usr/bin/find
    usr/bin/gawk
    usr/bin/grep
    usr/bin/gzip
    usr/bin/make
    usr/bin/patch
    usr/bin/sed
    usr/bin/tar
    usr/bin/xz
    usr/bin/ld
    usr/bin/readelf
    usr/bin/gcc
    usr/bin/g++
    usr/bin/cc
    usr/sbin/ldconfig
    usr/lib/libc.so.6
    usr/lib/ld-linux-x86-64.so.2
)

printf '\n[USERSPACE-TEST] Validating alpha.2 sysroot\n'

for relative in "${REQUIRED_FILES[@]}"; do
    require_sysroot_file "${relative}"

    printf '[USERSPACE-TEST] OK: %s\n' \
        "${relative}"
done

[[ -L "${VEYR_SYSROOT}/usr/bin/sh" ]] \
    || die "Expected /usr/bin/sh to be a symlink to Bash"

[[ "$(readlink "${VEYR_SYSROOT}/usr/bin/sh")" == "bash" ]] \
    || die "/usr/bin/sh does not point to bash"

[[ -e "${SYSROOT_INTERPRETER}" ]] \
    || die "Sysroot PT_INTERP path is missing: ${SYSROOT_INTERPRETER}"

[[ -e "${SYSROOT_LOADER}" ]] \
    || die "Canonical Glibc loader is missing: ${SYSROOT_LOADER}"

RESOLVED_INTERPRETER="$(
    readlink -f "${SYSROOT_INTERPRETER}"
)"

RESOLVED_LOADER="$(
    readlink -f "${SYSROOT_LOADER}"
)"

[[ "${RESOLVED_INTERPRETER}" == "${RESOLVED_LOADER}" ]] \
    || die "Sysroot /lib64 loader does not resolve to the installed Glibc loader"

require_cross_tool readelf

check_sysroot_binary() {
    local relative="$1"
    local binary="${VEYR_SYSROOT}/${relative}"
    local interpreter
    local listing

    [[ -x "${binary}" ]] \
        || die "Required executable is missing: ${relative}"

    interpreter="$(
        "${VEYR_TARGET}-readelf" \
            -l "${binary}" 2>/dev/null \
        | sed -n \
            's@.*Requesting program interpreter: \(.*\)]@\1@p'
    )"

    [[ "${interpreter}" == "${EXPECTED_INTERPRETER}" ]] \
        || die "Unexpected interpreter for ${relative}: ${interpreter:-<missing>}"

    listing="$(
        "${SYSROOT_LOADER}" \
            --library-path "${LIBRARY_PATH}" \
            --list "${binary}" 2>&1
    )" || {
        printf '%s\n' "${listing}" >&2

        die "Unable to resolve runtime dependencies for ${relative}"
    }

    if grep -q 'not found' <<<"${listing}"; then
        printf '%s\n' "${listing}" >&2

        die "Unresolved runtime dependency for ${relative}"
    fi

    printf '[USERSPACE-TEST] ELF OK: /%s\n' \
        "${relative}"
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
    check_sysroot_binary "${binary}"
done

printf '%s\n' \
    '[USERSPACE-TEST] Executing Bash through the Veyr Glibc loader'

"${SYSROOT_LOADER}" \
    --library-path "${LIBRARY_PATH}" \
    "${VEYR_SYSROOT}/usr/bin/bash" \
    --noprofile \
    --norc \
    -c 'printf "Veyr sysroot Bash smoke test: PASS\n"'

LDCONFIG="${VEYR_SYSROOT}/usr/sbin/ldconfig"

LDCONFIG_INFO="$(
    file "${LDCONFIG}"
)"

printf '[USERSPACE-TEST] ldconfig: %s\n' \
    "${LDCONFIG_INFO}"

if ! grep -Eqi 'static|statically linked' <<<"${LDCONFIG_INFO}"; then
    echo "Veyr ldconfig must be static for alpha.2 image generation." >&2
    exit 1
fi

TEST_OUT="${ROOT_DIR}/out/tests/userspace"

rm -rf "${TEST_OUT}"

mkdir -p "${TEST_OUT}"

cp \
    "${ROOT_DIR}/tests/userspace/smoke.sh" \
    "${TEST_OUT}/smoke.sh"

chmod +x \
    "${TEST_OUT}/smoke.sh"

printf '[USERSPACE-TEST] Runtime smoke test prepared: %s\n' \
    "${TEST_OUT}/smoke.sh"

success "Host-side alpha.2 userspace validation passed"