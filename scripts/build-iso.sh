#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

ensure_dirs

ISO_ROOT="${BUILD_DIR}/iso-root"

KERNEL="${OUT_DIR}/kernel/vmlinuz-${LINUX_VERSION}"
INITRAMFS="${OUT_DIR}/initramfs/veyr-initramfs-${VEYR_VERSION}.img"

ISO_FILE="${OUT_DIR}/Veyr-${VEYR_VERSION}-bootstrap-x86_64.iso"

[[ -f "${KERNEL}" ]] \
    || die "Kernel not found"

[[ -f "${INITRAMFS}" ]] \
    || die "Initramfs not found"

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

log "Creating Veyr ISO"

rm -f "${ISO_FILE}"

grub2-mkrescue \
    -o "${ISO_FILE}" \
    "${ISO_ROOT}"

[[ -f "${ISO_FILE}" ]] \
    || die "ISO creation failed"

success "ISO created:"
echo "${ISO_FILE}"

echo
sha256sum "${ISO_FILE}"