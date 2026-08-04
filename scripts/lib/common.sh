#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CONFIG_DIR="${ROOT_DIR}/config"
SOURCES_DIR="${ROOT_DIR}/sources"
BUILD_DIR="${ROOT_DIR}/build"
OUT_DIR="${ROOT_DIR}/out"

VEYR_VERSION="$(tr -d '[:space:]' < "${ROOT_DIR}/VERSION")"

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
    command -v "$1" >/dev/null 2>&1 \
        || die "Required command not found: $1"
}

ensure_dirs() {
    mkdir -p \
        "${SOURCES_DIR}" \
        "${BUILD_DIR}" \
        "${OUT_DIR}"
}