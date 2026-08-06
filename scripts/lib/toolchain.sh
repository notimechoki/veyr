#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -z "${VEYR_ROOT:-}" ]]; then
    TOOLCHAIN_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    VEYR_ROOT="$(cd "${TOOLCHAIN_LIB_DIR}/../.." && pwd)"
fi

source "${VEYR_ROOT}/config/toolchain.env"

VEYR_SYSROOT="${VEYR_ROOT}/out/sysroot"
VEYR_TOOLS="${VEYR_SYSROOT}/tools"
VEYR_CONFIG_SITE="${VEYR_SYSROOT}/usr/share/config.site"

export VEYR_TARGET
export VEYR_SYSROOT
export VEYR_TOOLS
export VEYR_CONFIG_SITE

export LC_ALL=POSIX
export PATH="${VEYR_TOOLS}/bin:${PATH}"

umask 022

enable_veyr_config_site() {
    if [[ -f "${VEYR_CONFIG_SITE}" ]]; then
        export CONFIG_SITE="${VEYR_CONFIG_SITE}"
    else
        unset CONFIG_SITE || true
    fi
}

ensure_veyr_layout() {
    mkdir -p \
        "${VEYR_SYSROOT}/etc" \
        "${VEYR_SYSROOT}/var" \
        "${VEYR_SYSROOT}/usr/bin" \
        "${VEYR_SYSROOT}/usr/lib" \
        "${VEYR_SYSROOT}/usr/sbin" \
        "${VEYR_SYSROOT}/usr/include" \
        "${VEYR_SYSROOT}/usr/share" \
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

require_sysroot_file() {
    local relative="$1"

    [[ -e "${VEYR_SYSROOT}/${relative}" ]] || {
        echo "Missing Veyr sysroot file: ${relative}" >&2
        exit 1
    }
}