#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

ensure_dirs

IMAGE_PROFILE="${1:-bootstrap}"
BUSYBOX_ROOT="${OUT_DIR}/packages/busybox/rootfs"
ROOTFS_BUILD="${BUILD_DIR}/images/${IMAGE_PROFILE}/rootfs"
IMAGE_OUT="${OUT_DIR}/images/${IMAGE_PROFILE}"
INITRAMFS_FILE="${IMAGE_OUT}/initramfs.img"

[[ -x "${BUSYBOX_ROOT}/bin/busybox" ]] \
    || die "BusyBox package output not found. Run: ./veyr build busybox"

log "Preparing Veyr ${VEYR_VERSION} ${IMAGE_PROFILE} root filesystem"

rm -rf "${ROOTFS_BUILD}"
mkdir -p "${ROOTFS_BUILD}" "${IMAGE_OUT}"

cp -a "${BUSYBOX_ROOT}/." "${ROOTFS_BUILD}/"

mkdir -p \
    "${ROOTFS_BUILD}/dev" \
    "${ROOTFS_BUILD}/proc" \
    "${ROOTFS_BUILD}/sys" \
    "${ROOTFS_BUILD}/run" \
    "${ROOTFS_BUILD}/tmp" \
    "${ROOTFS_BUILD}/root" \
    "${ROOTFS_BUILD}/etc"

cp "${ROOT_DIR}/rootfs/common/etc/motd" "${ROOTFS_BUILD}/etc/motd"

sed \
    "s/@VERSION@/${VEYR_VERSION}/g" \
    "${ROOT_DIR}/rootfs/common/etc/os-release.in" \
    > "${ROOTFS_BUILD}/etc/os-release"

printf '%s\n' "${IMAGE_PROFILE}" > "${ROOTFS_BUILD}/etc/veyr-image-profile"

cp "${ROOT_DIR}/initramfs/init" "${ROOTFS_BUILD}/init"
chmod +x "${ROOTFS_BUILD}/init"

if [[ "${IMAGE_PROFILE}" == "base-alpha1" ]]; then
    SYSROOT="${OUT_DIR}/sysroot"
    TEST_BINARY="${OUT_DIR}/tests/toolchain/veyr-toolchain-test"

    [[ -e "${SYSROOT}/usr/lib/libc.so.6" ]] \
        || die "Veyr bootstrap Glibc not found. Run: ./veyr build --profile base-alpha1"

    [[ -e "${SYSROOT}/usr/lib/ld-linux-x86-64.so.2" ]] \
        || die "Veyr Glibc loader not found."

    [[ -x "${TEST_BINARY}" ]] \
        || die "Toolchain VM test binary not found. Run: ./scripts/build-toolchain-test.sh"

    log "Adding Veyr Glibc and cross-toolchain test binary to alpha.1 initramfs"

    mkdir -p \
        "${ROOTFS_BUILD}/usr/bin" \
        "${ROOTFS_BUILD}/usr/lib" \
        "${ROOTFS_BUILD}/lib64"

    cp -L \
        "${SYSROOT}/usr/lib/libc.so.6" \
        "${ROOTFS_BUILD}/usr/lib/libc.so.6"

    cp -L \
        "${SYSROOT}/usr/lib/ld-linux-x86-64.so.2" \
        "${ROOTFS_BUILD}/usr/lib/ld-linux-x86-64.so.2"

    ln -sfn \
        ../usr/lib/ld-linux-x86-64.so.2 \
        "${ROOTFS_BUILD}/lib64/ld-linux-x86-64.so.2"

    cp "${TEST_BINARY}" "${ROOTFS_BUILD}/usr/bin/veyr-toolchain-test"
    chmod +x "${ROOTFS_BUILD}/usr/bin/veyr-toolchain-test"
fi

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

[[ -f "${INITRAMFS_FILE}" ]] || die "Initramfs was not created"

success "Initramfs created: ${INITRAMFS_FILE}"