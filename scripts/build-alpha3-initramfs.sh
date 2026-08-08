#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(
    cd "$(dirname "${BASH_SOURCE[0]}")" \
    && pwd
)"

source "${SCRIPT_DIR}/lib/common.sh"

ensure_dirs

PROFILE=base-alpha3

BUSYBOX_ROOT="${OUT_DIR}/packages/busybox/rootfs"
BUSYBOX_BIN="${BUSYBOX_ROOT}/bin/busybox"

EARLY_INIT="${ROOT_DIR}/initramfs/alpha3-init"

INITRAMFS_ROOT="${BUILD_DIR}/images/${PROFILE}/initramfs-root"

IMAGE_OUT="${OUT_DIR}/images/${PROFILE}"
INITRAMFS_FILE="${IMAGE_OUT}/initramfs.img"

MAX_INITRAMFS_MB="${VEYR_ALPHA3_MAX_INITRAMFS_MB:-64}"

[[ -x "${BUSYBOX_BIN}" ]] \
    || die "BusyBox package output not found"

[[ -x "${EARLY_INIT}" ]] \
    || die "Alpha.3 early init is missing or not executable"

BUSYBOX_INFO="$(
    file "${BUSYBOX_BIN}"
)"

if ! grep -qi 'statically linked' <<<"${BUSYBOX_INFO}"; then
    die "Alpha.3 early BusyBox must be static: ${BUSYBOX_INFO}"
fi

APPLET_LIST="$(
    "${BUSYBOX_BIN}" --list
)"

for applet in \
    switch_root \
    mount \
    sleep \
    sh; do

    if ! grep -qx "${applet}" <<<"${APPLET_LIST}"; then
        die "BusyBox applet required by alpha.3 is missing: ${applet}"
    fi

done

log "Building small alpha.3 early initramfs"

rm -rf "${INITRAMFS_ROOT}"

mkdir -p \
    "${INITRAMFS_ROOT}" \
    "${IMAGE_OUT}"

cp -a \
    "${BUSYBOX_ROOT}/." \
    "${INITRAMFS_ROOT}/"

mkdir -p \
    "${INITRAMFS_ROOT}/dev" \
    "${INITRAMFS_ROOT}/proc" \
    "${INITRAMFS_ROOT}/sys" \
    "${INITRAMFS_ROOT}/run" \
    "${INITRAMFS_ROOT}/tmp" \
    "${INITRAMFS_ROOT}/newroot" \
    "${INITRAMFS_ROOT}/etc"

chmod 1777 \
    "${INITRAMFS_ROOT}/tmp"

cp \
    "${EARLY_INIT}" \
    "${INITRAMFS_ROOT}/init"

chmod 0755 \
    "${INITRAMFS_ROOT}/init"

sed \
    "s/@VERSION@/${VEYR_VERSION}/g" \
    "${ROOT_DIR}/rootfs/common/etc/os-release.in" \
    > "${INITRAMFS_ROOT}/etc/os-release"

printf '%s\n' \
    "${PROFILE}-early" \
    > "${INITRAMFS_ROOT}/etc/veyr-image-profile"

(
    cd "${INITRAMFS_ROOT}"

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

[[ -s "${INITRAMFS_FILE}" ]] \
    || die "Alpha.3 initramfs was not created"

SIZE_BYTES="$(
    stat -c '%s' "${INITRAMFS_FILE}"
)"

MAX_BYTES=$((MAX_INITRAMFS_MB * 1024 * 1024))

if (( SIZE_BYTES > MAX_BYTES )); then
    die "Alpha.3 initramfs is too large: ${SIZE_BYTES} bytes (limit ${MAX_INITRAMFS_MB} MiB)"
fi

success "Alpha.3 small initramfs created: ${INITRAMFS_FILE}"

du -h "${INITRAMFS_FILE}"