#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

ensure_dirs

ISO_ROOT="${BUILD_DIR}/images/bootstrap/iso-root"

IMAGE_OUT="${OUT_DIR}/images/bootstrap"

KERNEL="${OUT_DIR}/packages/linux/vmlinuz"

INITRAMFS="${IMAGE_OUT}/initramfs.img"

ISO_FILE="${IMAGE_OUT}/Veyr-${VEYR_VERSION}-bootstrap-x86_64.iso"

[[ -f "${KERNEL}" ]] \
    || die "Kernel package output not found. Run: ./veyr build linux"

[[ -f "${INITRAMFS}" ]] \
    || die "Initramfs not found. Run: ./scripts/build-initramfs.sh"

require_command grub2-mkrescue
require_command xorriso

log "Preparing ISO filesystem"

rm -rf "${ISO_ROOT}"

mkdir -p \
    "${ISO_ROOT}/boot/grub"

cp \
    "${KERNEL}" \
    "${ISO_ROOT}/boot/vmlinuz"

cp \
    "${INITRAMFS}" \
    "${ISO_ROOT}/boot/initramfs.img"

cp \
    "${ROOT_DIR}/iso/grub/grub.cfg" \
    "${ISO_ROOT}/boot/grub/grub.cfg"

log "Creating Veyr ${VEYR_VERSION} bootstrap ISO"

rm -f "${ISO_FILE}"

grub2-mkrescue \
    -o "${ISO_FILE}" \
    "${ISO_ROOT}"

[[ -f "${ISO_FILE}" ]] \
    || die "ISO creation failed"

success "ISO created: ${ISO_FILE}"

echo

sha256sum "${ISO_FILE}"