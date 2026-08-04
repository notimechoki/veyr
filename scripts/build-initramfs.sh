#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

ensure_dirs

BUSYBOX_ROOT="${OUT_DIR}/packages/busybox/rootfs"

ROOTFS_BUILD="${BUILD_DIR}/images/bootstrap/rootfs"

IMAGE_OUT="${OUT_DIR}/images/bootstrap"

INITRAMFS_FILE="${IMAGE_OUT}/initramfs.img"

[[ -x "${BUSYBOX_ROOT}/bin/busybox" ]] \
    || die "BusyBox package output not found. Run: ./veyr build busybox"

log "Preparing Veyr ${VEYR_VERSION} bootstrap root filesystem"

rm -rf "${ROOTFS_BUILD}"

mkdir -p \
    "${ROOTFS_BUILD}" \
    "${IMAGE_OUT}"

cp -a \
    "${BUSYBOX_ROOT}/." \
    "${ROOTFS_BUILD}/"

mkdir -p \
    "${ROOTFS_BUILD}/dev" \
    "${ROOTFS_BUILD}/proc" \
    "${ROOTFS_BUILD}/sys" \
    "${ROOTFS_BUILD}/run" \
    "${ROOTFS_BUILD}/tmp" \
    "${ROOTFS_BUILD}/root" \
    "${ROOTFS_BUILD}/etc"

cp \
    "${ROOT_DIR}/rootfs/common/etc/motd" \
    "${ROOTFS_BUILD}/etc/motd"

sed \
    "s/@VERSION@/${VEYR_VERSION}/g" \
    "${ROOT_DIR}/rootfs/common/etc/os-release.in" \
    > "${ROOTFS_BUILD}/etc/os-release"

cp \
    "${ROOT_DIR}/initramfs/init" \
    "${ROOTFS_BUILD}/init"

chmod +x "${ROOTFS_BUILD}/init"

log "Creating compressed initramfs"

(
    cd "${ROOTFS_BUILD}"

    find . -print0 \
        | sort -z \
        | cpio \
            --null \
            --create \
            --format=newc \
            --owner=0:0 \
        | gzip -9 \
        > "${INITRAMFS_FILE}"
)

[[ -f "${INITRAMFS_FILE}" ]] \
    || die "Initramfs was not created"

success "Initramfs created: ${INITRAMFS_FILE}"