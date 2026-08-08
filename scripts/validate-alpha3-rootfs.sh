#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

export VEYR_ROOT="${ROOT_DIR}"

source "${ROOT_DIR}/scripts/lib/common.sh"
source "${ROOT_DIR}/scripts/lib/toolchain.sh"

ROOTFS="${1:-${ROOT_DIR}/build/images/base-alpha3/rootfs}"

[[ -d "${ROOTFS}" ]] \
    || die "Alpha.3 staging rootfs does not exist: ${ROOTFS}"

LOADER="${ROOTFS}/lib64/ld-linux-x86-64.so.2"
BUSYBOX="${ROOTFS}/usr/libexec/busybox"
LDCONFIG="${ROOTFS}/usr/sbin/ldconfig"

[[ -f "${LOADER}" && ! -L "${LOADER}" && -x "${LOADER}" ]] \
    || die "Alpha.3 ELF loader is missing or invalid"

[[ -x "${BUSYBOX}" ]] \
    || die "Alpha.3 static BusyBox is missing"

if ! file "${BUSYBOX}" | grep -qi 'statically linked'; then
    die "Alpha.3 BusyBox is not static"
fi

[[ -x "${ROOTFS}/sbin/init" ]] \
    || die "Alpha.3 /sbin/init is missing"

[[ -x "${ROOTFS}/usr/lib/veyr-tests/rootfs-alpha3-smoke.sh" ]] \
    || die "Alpha.3 runtime smoke test is missing"

[[ -s "${ROOTFS}/etc/ld.so.cache" ]] \
    || die "Alpha.3 loader cache is missing"

require_cross_tool readelf

EXPECTED_INTERPRETER=/lib64/ld-linux-x86-64.so.2

LIBRARY_PATH="${ROOTFS}/usr/lib:${ROOTFS}/lib"

check_binary() {
    local relative="$1"
    local binary="${ROOTFS}/${relative}"
    local interpreter
    local listing

    [[ -x "${binary}" ]] \
        || die "Missing alpha.3 executable: /${relative}"

    interpreter="$(
        "${VEYR_TARGET}-readelf" \
            -l "${binary}" \
            2>/dev/null \
        | sed -n \
            's@.*Requesting program interpreter: \(.*\)]@\1@p'
    )"

    [[ "${interpreter}" == "${EXPECTED_INTERPRETER}" ]] \
        || die "Unexpected interpreter for /${relative}: ${interpreter:-<missing>}"

    listing="$(
        "${LOADER}" \
            --library-path "${LIBRARY_PATH}" \
            --list "${binary}" \
            2>&1
    )" || {
        printf '%s\n' "${listing}" >&2

        die "Unable to resolve /${relative}"
    }

    if grep -q 'not found' <<<"${listing}"; then
        printf '%s\n' "${listing}" >&2

        die "Unresolved library for /${relative}"
    fi

    printf '[ALPHA3-ROOTFS] OK: /%s\n' \
        "${relative}"
}

for binary in \
    usr/bin/bash \
    usr/bin/ls \
    usr/bin/cat \
    usr/bin/grep \
    usr/bin/df \
    usr/bin/file \
    usr/bin/make \
    usr/bin/gcc \
    usr/bin/g++; do

    check_binary "${binary}"
done

CACHE_LISTING="$(
    "${LDCONFIG}" \
        -r "${ROOTFS}" \
        -p
)"

for soname in \
    libc.so.6 \
    libm.so.6 \
    libncursesw.so.6 \
    libstdc++.so.6 \
    libgcc_s.so.1; do

    grep -Fq "${soname}" <<<"${CACHE_LISTING}" \
        || die "Alpha.3 loader cache does not contain ${soname}"
done

success "Alpha.3 staging rootfs validation passed"