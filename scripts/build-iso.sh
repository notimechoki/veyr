#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_ISO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${BUILD_ISO_DIR}/lib/common.sh"

ensure_dirs

IMAGE_PROFILE="${1:-bootstrap}"

ISO_ROOT="${BUILD_DIR}/images/${IMAGE_PROFILE}/iso-root"
IMAGE_OUT="${OUT_DIR}/images/${IMAGE_PROFILE}"

KERNEL="${OUT_DIR}/packages/linux/vmlinuz"
INITRAMFS="${IMAGE_OUT}/initramfs.img"

ISO_FILE="${IMAGE_OUT}/Veyr-${VEYR_VERSION}-${IMAGE_PROFILE}-x86_64.iso"

PROFILE_GRUB="${ROOT_DIR}/iso/grub/${IMAGE_PROFILE}.cfg"
DEFAULT_GRUB="${ROOT_DIR}/iso/grub/grub.cfg"

[[ -f "${KERNEL}" ]] \
    || die "Kernel package output not found. Run: ./veyr build linux"

[[ -f "${INITRAMFS}" ]] \
    || die "Initramfs not found for profile ${IMAGE_PROFILE}"

require_command grub2-mkrescue
require_command xorriso

if [[ -f "${PROFILE_GRUB}" ]]; then
    GRUB_CONFIG="${PROFILE_GRUB}"
else
    GRUB_CONFIG="${DEFAULT_GRUB}"
fi

[[ -f "${GRUB_CONFIG}" ]] \
    || die "GRUB config not found for ${IMAGE_PROFILE}"

log "Preparing ${IMAGE_PROFILE} ISO filesystem"
log "GRUB config: ${GRUB_CONFIG#${ROOT_DIR}/}"

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
    "${GRUB_CONFIG}" \
    "${ISO_ROOT}/boot/grub/grub.cfg"

log "Creating Veyr ${VEYR_VERSION} ${IMAGE_PROFILE} ISO"

rm -f "${ISO_FILE}"

grub2-mkrescue \
    -o "${ISO_FILE}" \
    "${ISO_ROOT}"

[[ -f "${ISO_FILE}" ]] \
    || die "ISO creation failed"

success "ISO created: ${ISO_FILE}"

echo

sha256sum "${ISO_FILE}"