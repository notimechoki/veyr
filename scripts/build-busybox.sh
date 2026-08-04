#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

ensure_dirs

BUSYBOX_SOURCE="${SOURCES_DIR}/${BUSYBOX_ARCHIVE}"
BUSYBOX_BUILD="${BUILD_DIR}/busybox-${BUSYBOX_VERSION}"
BUSYBOX_ROOT="${BUILD_DIR}/busybox-root"

[[ -f "${BUSYBOX_SOURCE}" ]] \
    || die "BusyBox source archive not found. Run fetch-sources.sh first."

log "Cleaning previous BusyBox build"

rm -rf \
    "${BUSYBOX_BUILD}" \
    "${BUSYBOX_ROOT}"

mkdir -p \
    "${BUSYBOX_BUILD}" \
    "${BUSYBOX_ROOT}"

log "Extracting BusyBox ${BUSYBOX_VERSION}"

tar \
    -xf "${BUSYBOX_SOURCE}" \
    --strip-components=1 \
    -C "${BUSYBOX_BUILD}"

cd "${BUSYBOX_BUILD}"

log "Creating BusyBox default configuration"

make defconfig

log "Enabling static BusyBox binary"

if grep -q '^# CONFIG_STATIC is not set' .config; then
    sed -i \
        's/^# CONFIG_STATIC is not set$/CONFIG_STATIC=y/' \
        .config
elif grep -q '^CONFIG_STATIC=' .config; then
    sed -i \
        's/^CONFIG_STATIC=.*/CONFIG_STATIC=y/' \
        .config
else
    echo 'CONFIG_STATIC=y' >> .config
fi

log "Disabling BusyBox tc applet"

if grep -q '^CONFIG_TC=y' .config; then
    sed -i \
        's/^CONFIG_TC=y$/# CONFIG_TC is not set/' \
        .config
fi

if grep -q '^CONFIG_FEATURE_TC_INGRESS=y' .config; then
    sed -i \
        's/^CONFIG_FEATURE_TC_INGRESS=y$/# CONFIG_FEATURE_TC_INGRESS is not set/' \
        .config
fi

log "BusyBox bootstrap configuration"

grep -E \
    '^(CONFIG_STATIC=|# CONFIG_TC|# CONFIG_FEATURE_TC_INGRESS)' \
    .config \
    || true

log "Building BusyBox"

make -j"$(nproc)"

log "Installing BusyBox into temporary root"

make CONFIG_PREFIX="${BUSYBOX_ROOT}" install

[[ -x "${BUSYBOX_ROOT}/bin/busybox" ]] \
    || die "BusyBox binary was not created"

log "Checking BusyBox binary"

BUSYBOX_FILE_INFO="$(file "${BUSYBOX_ROOT}/bin/busybox")"

echo "${BUSYBOX_FILE_INFO}"

if echo "${BUSYBOX_FILE_INFO}" | grep -qi "statically linked"; then
    success "BusyBox is statically linked"
else
    warning "BusyBox does not appear to be statically linked"

    if command -v ldd >/dev/null 2>&1; then
        ldd "${BUSYBOX_ROOT}/bin/busybox" || true
    fi
fi

success "BusyBox build completed"