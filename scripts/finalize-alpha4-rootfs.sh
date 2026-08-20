#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

ensure_dirs

PROFILE=base-alpha4
ROOTFS_BUILD="${BUILD_DIR}/images/${PROFILE}/rootfs"
IMAGE_OUT="${OUT_DIR}/images/${PROFILE}"
ROOTFS_IMAGE="${IMAGE_OUT}/veyr-rootfs.ext4"
ROOTFS_SIZE_MB="${VEYR_ALPHA4_ROOTFS_MB:-8192}"

require_command truncate
require_command mkfs.ext4
require_command e2fsck

if (( EUID == 0 )); then
    SUDO=()
else
    require_command sudo
    SUDO=(sudo)
fi

[[ -d "${ROOTFS_BUILD}" ]] \
    || die "Alpha.4 staging rootfs is missing. Build temporary-alpha4 first."

for marker in \
    gettext-native \
    bison-native \
    perl-native \
    zlib-native \
    mpdecimal-native \
    python-native \
    texinfo-native \
    util-linux-native; do

    [[ -f "${ROOTFS_BUILD}/usr/lib/veyr/native-build/${marker}.stamp" ]] \
        || die "Native build marker missing: ${marker}"
done

log "Finalizing alpha.4 native chroot filesystem"

printf '%s\n' 'alpha4-native-complete' \
    | "${SUDO[@]}" tee "${ROOTFS_BUILD}/etc/veyr-stage" >/dev/null

#
# Chroot package builds run as root. Their build trees and temporary package
# directories can therefore contain root-owned files. Finalization is a
# host-side operation, so clean these paths with the same privilege boundary
# used for ldconfig/image ownership normalization.
#
log "Removing alpha.4 chroot build leftovers"

"${SUDO[@]}" rm -rf \
    "${ROOTFS_BUILD}/sources"/* \
    "${ROOTFS_BUILD}/tmp/veyr-build" \
    "${ROOTFS_BUILD}/tmp/veyr-package-out"

mkdir -p "${ROOTFS_BUILD}/sources"
chmod 1777 "${ROOTFS_BUILD}/sources" "${ROOTFS_BUILD}/tmp"

#
# Chroot package installation refreshes ld.so.cache as root. Rebuild it here
# with the same privileges so finalization never depends on cache ownership.
#
log "Refreshing alpha.4 dynamic loader cache"

"${SUDO[@]}" \
    "${ROOTFS_BUILD}/usr/sbin/ldconfig" \
    -r "${ROOTFS_BUILD}"

[[ -s "${ROOTFS_BUILD}/etc/ld.so.cache" ]] \
    || die "Alpha.4 loader cache was not generated"

"${SCRIPT_DIR}/validate-alpha4-rootfs.sh" \
    "${ROOTFS_BUILD}"

mkdir -p "${IMAGE_OUT}"
"${SUDO[@]}" rm -f "${ROOTFS_IMAGE}"

log "Creating sparse ${ROOTFS_SIZE_MB} MiB alpha.4 ext4 root image"

truncate \
    -s "${ROOTFS_SIZE_MB}M" \
    "${ROOTFS_IMAGE}"

HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
OWNERSHIP_NORMALIZED=0

restore_host_ownership() {
    if [[ "${OWNERSHIP_NORMALIZED}" -eq 1 ]]; then
        "${SUDO[@]}" \
            chown -R "${HOST_UID}:${HOST_GID}" \
            "${ROOTFS_BUILD}" \
            2>/dev/null \
            || true
    fi

    if [[ -e "${ROOTFS_IMAGE}" ]]; then
        "${SUDO[@]}" \
            chown "${HOST_UID}:${HOST_GID}" \
            "${ROOTFS_IMAGE}" \
            2>/dev/null \
            || true
    fi
}

trap restore_host_ownership EXIT INT TERM

log "Normalizing filesystem ownership to root inside the image"

"${SUDO[@]}" \
    chown -R 0:0 \
    "${ROOTFS_BUILD}"

OWNERSHIP_NORMALIZED=1

"${SUDO[@]}" \
    mkfs.ext4 \
    -F \
    -q \
    -L VEYR_ROOT \
    -m 0 \
    -d "${ROOTFS_BUILD}" \
    "${ROOTFS_IMAGE}"

"${SUDO[@]}" \
    chown "${HOST_UID}:${HOST_GID}" \
    "${ROOTFS_IMAGE}"

e2fsck \
    -fn \
    "${ROOTFS_IMAGE}"

[[ -s "${ROOTFS_IMAGE}" ]] \
    || die "Alpha.4 root filesystem image was not created"

restore_host_ownership
OWNERSHIP_NORMALIZED=0
trap - EXIT INT TERM

success "Alpha.4 root image created: ${ROOTFS_IMAGE}"

printf 'Logical size: '
du -h --apparent-size "${ROOTFS_IMAGE}" | awk '{print $1}'

printf 'Disk usage:   '
du -h "${ROOTFS_IMAGE}" | awk '{print $1}'
