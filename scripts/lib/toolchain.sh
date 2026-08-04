#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -z "${VEYR_ROOT:-}" ]]; then
    TOOLCHAIN_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    VEYR_ROOT="$(cd "${TOOLCHAIN_LIB_DIR}/../.." && pwd)"
fi

source "${VEYR_ROOT}/config/toolchain.env"

VEYR_SYSROOT="${VEYR_ROOT}/out/sysroot"
VEYR_TOOLS="${VEYR_SYSROOT}/tools"

export VEYR_TARGET
export VEYR_SYSROOT
export VEYR_TOOLS
export LC_ALL=POSIX

export PATH="${VEYR_TOOLS}/bin:${PATH}"

umask 022

ensure_veyr_layout() {
    mkdir -p \
        "${VEYR_SYSROOT}/etc" \
        "${VEYR_SYSROOT}/var" \
        "${VEYR_SYSROOT}/usr/bin" \
        "${VEYR_SYSROOT}/usr/lib" \
        "${VEYR_SYSROOT}/usr/sbin" \
        "${VEYR_SYSROOT}/usr/include" \
        "${VEYR_SYSROOT}/tools" \
        "${VEYR_SYSROOT}/lib64"

    ensure_root_link bin usr/bin
    ensure_root_link lib usr/lib
    ensure_root_link sbin usr/sbin
}

ensure_root_link() {
    local name="$1"
    local target="$2"
    local path="${VEYR_SYSROOT}/${name}"

    if [[ -L "${path}" ]]; then

        local current
        current="$(readlink "${path}")"

        if [[ "${current}" != "${target}" ]]; then
            echo "Unexpected Veyr sysroot symlink: ${path} -> ${current}" >&2
            exit 1
        fi

        return
    fi

    if [[ -e "${path}" ]]; then
        echo "Expected ${path} to be a symlink, but another filesystem object exists." >&2
        exit 1
    fi

    ln -s "${target}" "${path}"
}

require_cross_tool() {
    local tool="$1"

    command -v "${VEYR_TARGET}-${tool}" >/dev/null 2>&1 || {
        echo "Missing Veyr cross tool: ${VEYR_TARGET}-${tool}" >&2
        exit 1
    }
}