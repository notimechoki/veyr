#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

PROFILE=base-alpha4
KERNEL="${OUT_DIR}/packages/linux/vmlinuz"
INITRAMFS="${OUT_DIR}/images/${PROFILE}/initramfs.img"
ROOTFS_IMAGE="${OUT_DIR}/images/${PROFILE}/veyr-rootfs.ext4"

[[ -f "${KERNEL}" ]] || die "Kernel is missing"
[[ -f "${INITRAMFS}" ]] || die "Alpha.4 initramfs is missing"
[[ -f "${ROOTFS_IMAGE}" ]] || die "Alpha.4 rootfs image is missing"

QEMU_ARGS=(
    -name "Veyr ${VEYR_VERSION} alpha4 serial"
    -m "${VEYR_QEMU_MEMORY_MB:-2048}"
    -smp "${VEYR_QEMU_CPUS:-4}"
    -kernel "${KERNEL}"
    -initrd "${INITRAMFS}"
    -append "console=ttyS0 rdinit=/init loglevel=4"
    -drive "file=${ROOTFS_IMAGE},format=raw,if=virtio"
    -snapshot
    -nographic
)

if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    QEMU_ARGS+=(
        -enable-kvm
        -cpu host
    )
else
    warning "/dev/kvm unavailable. Using TCG."
    QEMU_ARGS+=(
        -accel tcg
        -cpu max
    )
fi

log "Starting alpha.4 serial debug VM"
log "Guest resources: ${VEYR_QEMU_MEMORY_MB:-2048} MiB RAM, ${VEYR_QEMU_CPUS:-4} vCPU"
log "Exit QEMU with Ctrl+A, then X"

exec qemu-system-x86_64 "${QEMU_ARGS[@]}"