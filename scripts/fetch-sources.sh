#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

ensure_dirs

download_and_verify() {
    local name="$1"
    local url="$2"
    local filename="$3"
    local expected_sha="$4"
    local destination="${SOURCES_DIR}/${filename}"

    log "Checking ${name}"

    if [[ ! -f "${destination}" ]]; then
        log "Downloading ${name}"
        curl \
            --fail \
            --location \
            --progress-bar \
            "${url}" \
            --output "${destination}"
    else
        log "${filename} already exists"
    fi

    log "Verifying SHA256 for ${filename}"

    local actual_sha
    actual_sha="$(sha256sum "${destination}" | awk '{print $1}')"

    if [[ "${actual_sha}" != "${expected_sha}" ]]; then
        rm -f "${destination}"

        die "SHA256 mismatch for ${filename}
Expected: ${expected_sha}
Actual:   ${actual_sha}"
    fi

    success "${name} verified"
}

download_and_verify \
    "Linux ${LINUX_VERSION}" \
    "${LINUX_URL}" \
    "${LINUX_ARCHIVE}" \
    "${LINUX_SHA256}"

download_and_verify \
    "BusyBox ${BUSYBOX_VERSION}" \
    "${BUSYBOX_URL}" \
    "${BUSYBOX_ARCHIVE}" \
    "${BUSYBOX_SHA256}"

success "All source archives are ready"