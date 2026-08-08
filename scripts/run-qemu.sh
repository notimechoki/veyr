#!/usr/bin/env bash

set -Eeuo pipefail

RUN_QEMU_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${RUN_QEMU_DIR}/lib/common.sh"

IMAGE_PROFILE="${1:-bootstrap}"

ISO_FILE="${OUT_DIR}/images/${IMAGE_PROFILE}/Veyr-${VEYR_VERSION}-${IMAGE_PROFILE}-x86_64.iso"

[[ -f "${ISO_FILE}" ]] \
    || die "Veyr ISO not found for ${IMAGE_PROFILE}. Build the profile image first."

MEMORY_MB=2048
CPU_COUNT=2

case "${IMAGE_PROFILE}" in

    base-alpha3)
        MEMORY_MB=2048
        CPU_COUNT=4
        ;;

    base-alpha2)
        MEMORY_MB=8192
        CPU_COUNT=4
        ;;

    base-alpha1|bootstrap)
        MEMORY_MB=2048
        CPU_COUNT=2
        ;;

esac

MEMORY_MB="${VEYR_QEMU_MEMORY_MB:-${MEMORY_MB}}"
CPU_COUNT="${VEYR_QEMU_CPUS:-${CPU_COUNT}}"

QEMU_ARGS=(
    -name "Veyr ${VEYR_VERSION} ${IMAGE_PROFILE}"
    -m "${MEMORY_MB}"
    -smp "${CPU_COUNT}"
    -cdrom "${ISO_FILE}"
    -boot d
    -display gtk
)

if [[ "${IMAGE_PROFILE}" == "base-alpha3" ]]; then
    ROOTFS_IMAGE="${OUT_DIR}/images/${IMAGE_PROFILE}/veyr-rootfs.ext4"

    [[ -f "${ROOTFS_IMAGE}" ]] \
        || die "Alpha.3 rootfs image is missing: ${ROOTFS_IMAGE}"

    QEMU_ARGS+=(
        -drive "file=${ROOTFS_IMAGE},format=raw,if=virtio"
        -snapshot
    )
fi

if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    log "KVM acceleration enabled"

    QEMU_ARGS+=(
        -enable-kvm
        -cpu host
    )
else
    warning "/dev/kvm unavailable. Using software emulation."

    QEMU_ARGS+=(
        -accel tcg
        -cpu max
    )
fi

log "Starting Veyr ${VEYR_VERSION} ${IMAGE_PROFILE}"
log "QEMU resources: ${MEMORY_MB} MiB RAM, ${CPU_COUNT} vCPU"

if [[ "${IMAGE_PROFILE}" == "base-alpha3" ]]; then
    log "Disk root: veyr-rootfs.ext4 (QEMU snapshot mode)"
fi

exec qemu-system-x86_64 "${QEMU_ARGS[@]}"