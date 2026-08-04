#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

ensure_dirs

KERNEL_SOURCE="${SOURCES_DIR}/${LINUX_ARCHIVE}"
KERNEL_BUILD="${BUILD_DIR}/linux-${LINUX_VERSION}"
KERNEL_OUT="${OUT_DIR}/kernel"

[[ -f "${KERNEL_SOURCE}" ]] || die "Linux source archive not found. Run fetch-sources.sh first."

rm -rf "${KERNEL_BUILD}"

mkdir -p \
    "${KERNEL_BUILD}" \
    "${KERNEL_OUT}"

log "Extracting Linux ${LINUX_VERSION}"

tar \
    -xf "${KERNEL_SOURCE}" \
    --strip-components=1 \
    -C "${KERNEL_BUILD}"

cd "${KERNEL_BUILD}"

log "Creating default x86_64 kernel configuration"

make defconfig

log "Enabling options required by Veyr bootstrap"

scripts/config --enable BLK_DEV_INITRD
scripts/config --enable DEVTMPFS
scripts/config --enable DEVTMPFS_MOUNT
scripts/config --enable TMPFS
scripts/config --enable PROC_FS
scripts/config --enable SYSFS
scripts/config --enable TTY
scripts/config --enable VT
scripts/config --enable VT_CONSOLE
scripts/config --enable VGA_CONSOLE
scripts/config --enable SERIAL_8250
scripts/config --enable SERIAL_8250_CONSOLE

make olddefconfig

log "Building Veyr kernel"

make -j"$(nproc)"

[[ -f "arch/x86/boot/bzImage" ]] \
    || die "Kernel bzImage not found"

cp \
    arch/x86/boot/bzImage \
    "${KERNEL_OUT}/vmlinuz-${LINUX_VERSION}"

cp \
    .config \
    "${KERNEL_OUT}/config-${LINUX_VERSION}"

success "Linux kernel ${LINUX_VERSION} built"