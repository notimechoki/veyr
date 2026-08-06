#!/usr/bin/env bash

set -Eeuo pipefail


COMMON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${ROOT_DIR:-}" ]]; then
    ROOT_DIR="$(cd "${COMMON_LIB_DIR}/../.." && pwd)"
fi

CONFIG_DIR="${ROOT_DIR}/config"
SOURCES_DIR="${ROOT_DIR}/sources"
BUILD_DIR="${ROOT_DIR}/build"
OUT_DIR="${ROOT_DIR}/out"

VERSION_FILE="${ROOT_DIR}/VERSION"

[[ -f "${VERSION_FILE}" ]] || {
    printf '\033[1;31m[ERROR]\033[0m VERSION file not found: %s\n' \
        "${VERSION_FILE}" >&2
    exit 1
}

VEYR_VERSION="$(
    tr -d '[:space:]' < "${VERSION_FILE}"
)"

log() {
    printf '\n\033[1;34m[VEYR]\033[0m %s\n' "$*"
}

success() {
    printf '\033[1;32m[OK]\033[0m %s\n' "$*"
}

warning() {
    printf '\033[1;33m[WARN]\033[0m %s\n' "$*"
}

die() {
    printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
    exit 1
}

require_command() {
    local command_name="$1"

    command -v "${command_name}" >/dev/null 2>&1 \
        || die "Required command not found: ${command_name}"
}

ensure_dirs() {
    mkdir -p \
        "${SOURCES_DIR}" \
        "${BUILD_DIR}" \
        "${OUT_DIR}"
}