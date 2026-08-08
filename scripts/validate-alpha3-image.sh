#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

PROFILE=base-alpha3

IMAGE_OUT="${OUT_DIR}/images/${PROFILE}"

ROOTFS_IMAGE="${IMAGE_OUT}/veyr-rootfs.ext4"
INITRAMFS_FILE="${IMAGE_OUT}/initramfs.img"

KERNEL="${OUT_DIR}/packages/linux/vmlinuz"
KERNEL_CONFIG="${OUT_DIR}/packages/linux/config"

require_command e2fsck
require_command debugfs
require_command file

[[ -s "${ROOTFS_IMAGE}" ]] \
    || die "Alpha.3 ext4 root image is missing"

[[ -s "${INITRAMFS_FILE}" ]] \
    || die "Alpha.3 initramfs is missing"

[[ -s "${KERNEL}" ]] \
    || die "Veyr kernel is missing"

[[ -s "${KERNEL_CONFIG}" ]] \
    || die "Veyr kernel config is missing"

for config in \
    CONFIG_BLK_DEV_INITRD=y \
    CONFIG_DEVTMPFS=y \
    CONFIG_EXT4_FS=y \
    CONFIG_VIRTIO=y \
    CONFIG_VIRTIO_PCI=y \
    CONFIG_VIRTIO_BLK=y; do

    grep -qx "${config}" "${KERNEL_CONFIG}" \
        || die "Kernel lacks required alpha.3 option: ${config}"
done

FILE_INFO="$(file "${ROOTFS_IMAGE}")"

printf '[ALPHA3-IMAGE] Root image: %s\n' \
    "${FILE_INFO}"

grep -qi 'ext4 filesystem data' <<<"${FILE_INFO}" \
    || die "Alpha.3 root image is not ext4"

e2fsck \
    -fn \
    "${ROOTFS_IMAGE}"

for path in \
    /usr/sbin/init \
    /usr/bin/bash \
    /usr/bin/gcc \
    /usr/bin/g++ \
    /usr/lib/veyr-tests/rootfs-alpha3-smoke.sh \
    /etc/ld.so.cache; do

    debugfs \
        -R "stat ${path}" \
        "${ROOTFS_IMAGE}" \
        2>/dev/null \
        | grep -q '^Inode:' \
        || die "Missing from alpha.3 ext4 image: ${path}"

    printf '[ALPHA3-IMAGE] OK: %s\n' \
        "${path}"
done

INITRAMFS_MB=$(((
    $(stat -c '%s' "${INITRAMFS_FILE}") + 1048575
) / 1048576))

printf '[ALPHA3-IMAGE] initramfs size: %s MiB\n' \
    "${INITRAMFS_MB}"

if (( INITRAMFS_MB > 64 )); then
    die "Alpha.3 initramfs exceeded the 64 MiB architecture target"
fi

success "Alpha.3 image validation passed"