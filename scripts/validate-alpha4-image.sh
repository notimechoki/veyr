#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

PROFILE=base-alpha4
IMAGE_OUT="${OUT_DIR}/images/${PROFILE}"
ROOTFS_IMAGE="${IMAGE_OUT}/veyr-rootfs.ext4"
INITRAMFS_FILE="${IMAGE_OUT}/initramfs.img"
KERNEL="${OUT_DIR}/packages/linux/vmlinuz"
KERNEL_CONFIG="${OUT_DIR}/packages/linux/config"

require_command e2fsck
require_command debugfs
require_command file

[[ -s "${ROOTFS_IMAGE}" ]] || die "Alpha.4 ext4 root image is missing"
[[ -s "${INITRAMFS_FILE}" ]] || die "Alpha.4 initramfs is missing"
[[ -s "${KERNEL}" ]] || die "Veyr kernel is missing"
[[ -s "${KERNEL_CONFIG}" ]] || die "Veyr kernel config is missing"

for config in \
    CONFIG_BLK_DEV_INITRD=y \
    CONFIG_DEVTMPFS=y \
    CONFIG_EXT4_FS=y \
    CONFIG_VIRTIO=y \
    CONFIG_VIRTIO_PCI=y \
    CONFIG_VIRTIO_BLK=y; do

    grep -qx "${config}" "${KERNEL_CONFIG}" \
        || die "Kernel lacks required alpha.4 option: ${config}"
done

FILE_INFO="$(file "${ROOTFS_IMAGE}")"
printf '[ALPHA4-IMAGE] Root image: %s\n' "${FILE_INFO}"
grep -qi 'ext4 filesystem data' <<<"${FILE_INFO}" \
    || die "Alpha.4 root image is not ext4"

e2fsck -fn "${ROOTFS_IMAGE}"

for path in \
    /usr/sbin/init \
    /usr/bin/bash \
    /usr/bin/gcc \
    /usr/bin/g++ \
    /usr/bin/msgfmt \
    /usr/bin/bison \
    /usr/bin/perl \
    /usr/bin/python3 \
    /usr/bin/makeinfo \
    /usr/bin/lsblk \
    /usr/lib/veyr/native-build/gettext-native.stamp \
    /usr/lib/veyr/native-build/python-native.stamp \
    /usr/lib/veyr/native-build/util-linux-native.stamp \
    /usr/lib/veyr-tests/native-alpha4-smoke.sh \
    /etc/ld.so.cache \
    /etc/veyr-stage; do

    stat_output="$(debugfs -R "stat ${path}" "${ROOTFS_IMAGE}" 2>/dev/null || true)"

    grep -q '^Inode:' <<<"${stat_output}" \
        || die "Missing from alpha.4 ext4 image: ${path}"

    printf '[ALPHA4-IMAGE] OK: %s\n' "${path}"
done

INITRAMFS_MB=$((( $(stat -c '%s' "${INITRAMFS_FILE}") + 1048575 ) / 1048576))
printf '[ALPHA4-IMAGE] initramfs size: %s MiB\n' "${INITRAMFS_MB}"

if (( INITRAMFS_MB > 64 )); then
    die "Alpha.4 initramfs exceeded the 64 MiB architecture target"
fi

success "Alpha.4 image validation passed"