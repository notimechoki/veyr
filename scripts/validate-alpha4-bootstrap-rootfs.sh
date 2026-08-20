#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
export VEYR_ROOT="${ROOT_DIR}"

source "${ROOT_DIR}/scripts/lib/common.sh"
source "${ROOT_DIR}/scripts/lib/toolchain.sh"

ROOTFS="${1:-${ROOT_DIR}/build/images/base-alpha4/rootfs}"
LOADER="${ROOTFS}/lib64/ld-linux-x86-64.so.2"
BUSYBOX="${ROOTFS}/usr/libexec/busybox"
LDCONFIG="${ROOTFS}/usr/sbin/ldconfig"
EXPECTED_INTERPRETER=/lib64/ld-linux-x86-64.so.2
LIBRARY_PATH="${ROOTFS}/usr/lib:${ROOTFS}/lib"

[[ -d "${ROOTFS}" ]] || die "Alpha.4 bootstrap rootfs does not exist: ${ROOTFS}"
[[ -f "${LOADER}" && ! -L "${LOADER}" && -x "${LOADER}" ]] \
    || die "Alpha.4 dynamic loader is missing or invalid"
[[ -x "${BUSYBOX}" ]] || die "Alpha.4 static BusyBox is missing"
[[ -x "${LDCONFIG}" ]] || die "Alpha.4 ldconfig is missing"
[[ -s "${ROOTFS}/etc/ld.so.cache" ]] || die "Alpha.4 loader cache is missing"
[[ -x "${ROOTFS}/sbin/init" ]] || die "Alpha.4 /sbin/init is missing"
[[ -d "${ROOTFS}/sources" ]] || die "Alpha.4 /sources is missing"

if ! file "${BUSYBOX}" | grep -qi 'statically linked'; then
    die "Alpha.4 BusyBox is not static"
fi

require_cross_tool readelf

for relative in \
    usr/bin/bash \
    usr/bin/gcc \
    usr/bin/g++ \
    usr/bin/make \
    usr/bin/env; do

    binary="${ROOTFS}/${relative}"
    [[ -x "${binary}" ]] || die "Missing alpha.4 bootstrap executable: /${relative}"

    interpreter="$(
        "${VEYR_TARGET}-readelf" -l "${binary}" 2>/dev/null \
            | sed -n 's@.*Requesting program interpreter: \(.*\)]@\1@p'
    )"

    [[ "${interpreter}" == "${EXPECTED_INTERPRETER}" ]] \
        || die "Unexpected ELF interpreter for /${relative}: ${interpreter:-<missing>}"

    listing="$(
        "${LOADER}" \
            --library-path "${LIBRARY_PATH}" \
            --list "${binary}" 2>&1
    )" || {
        printf '%s\n' "${listing}" >&2
        die "Unable to resolve runtime dependencies for /${relative}"
    }

    if grep -q 'not found' <<<"${listing}"; then
        printf '%s\n' "${listing}" >&2
        die "Unresolved runtime dependency for /${relative}"
    fi

    printf '[ALPHA4-BOOTSTRAP] OK: /%s\n' "${relative}"
done

success "Alpha.4 bootstrap rootfs validation passed"