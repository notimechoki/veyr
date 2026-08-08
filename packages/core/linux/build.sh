#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"
: "${VEYR_PACKAGE_OUT:?VEYR_PACKAGE_OUT is required}"
: "${VEYR_JOBS:?VEYR_JOBS is required}"

cd "${VEYR_SOURCE_DIR}"

rm -rf "${VEYR_PACKAGE_OUT}"
mkdir -p "${VEYR_PACKAGE_OUT}"

printf '\n[LINUX] Creating default x86_64 configuration\n'
make defconfig

printf '[LINUX] Enabling Veyr boot and disk-root options\n'
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

scripts/config --enable BLOCK
scripts/config --enable PCI
scripts/config --enable VIRTIO
scripts/config --enable VIRTIO_PCI
scripts/config --enable VIRTIO_BLK
scripts/config --enable EXT4_FS

make olddefconfig

for option in \
    CONFIG_BLK_DEV_INITRD=y \
    CONFIG_DEVTMPFS=y \
    CONFIG_EXT4_FS=y \
    CONFIG_VIRTIO=y \
    CONFIG_VIRTIO_PCI=y \
    CONFIG_VIRTIO_BLK=y; do
    grep -qx "${option}" .config || {
        echo "Required kernel option was not enabled: ${option}" >&2
        exit 1
    }
done

printf '[LINUX] Building kernel with %s jobs\n' "${VEYR_JOBS}"
make -j"${VEYR_JOBS}"

[[ -f arch/x86/boot/bzImage ]] || {
    echo 'Kernel bzImage was not created.' >&2
    exit 1
}

cp arch/x86/boot/bzImage "${VEYR_PACKAGE_OUT}/vmlinuz"
cp .config "${VEYR_PACKAGE_OUT}/config"

printf '[LINUX] Build complete\n'