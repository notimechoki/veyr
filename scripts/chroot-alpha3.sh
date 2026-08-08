#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

ROOTFS="${BUILD_DIR}/images/base-alpha3/rootfs"

[[ -x "${ROOTFS}/usr/bin/bash" ]] \
    || die "Alpha.3 staging rootfs is missing. Run: ./scripts/build-alpha3-rootfs.sh"

if (( EUID == 0 )); then
    SUDO=()
else
    require_command sudo

    SUDO=(sudo)
fi

MOUNTS=()

cleanup() {
    set +e

    for (( index=${#MOUNTS[@]}-1; index>=0; index-- )); do
        "${SUDO[@]}" \
            umount -l \
            "${MOUNTS[index]}" \
            2>/dev/null \
            || true
    done
}

trap cleanup EXIT INT TERM

mount_bind() {
    local source="$1"
    local target="$2"

    "${SUDO[@]}" \
        mount \
        --bind \
        "${source}" \
        "${target}"

    MOUNTS+=("${target}")
}

mount_fs() {
    local type="$1"
    local source="$2"
    local target="$3"

    "${SUDO[@]}" \
        mount \
        -t "${type}" \
        "${source}" \
        "${target}"

    MOUNTS+=("${target}")
}

log "Preparing alpha.3 chroot virtual filesystems"

mount_bind \
    /dev \
    "${ROOTFS}/dev"

mount_fs \
    devpts \
    devpts \
    "${ROOTFS}/dev/pts"

mount_fs \
    proc \
    proc \
    "${ROOTFS}/proc"

mount_fs \
    sysfs \
    sysfs \
    "${ROOTFS}/sys"

mount_fs \
    tmpfs \
    tmpfs \
    "${ROOTFS}/run"

if [[ "${1:-}" == "--" ]]; then
    shift
fi

if (( $# > 0 )); then
    CHROOT_COMMAND=("$@")
else
    CHROOT_COMMAND=(
        /usr/bin/bash
        --login
    )
fi

log "Entering Veyr alpha.3 chroot"

"${SUDO[@]}" \
    chroot \
    "${ROOTFS}" \
    /usr/bin/env -i \
    HOME=/root \
    TERM="${TERM:-xterm}" \
    PS1='(veyr-chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin:/bin:/sbin \
    MAKEFLAGS="-j$(nproc)" \
    "${CHROOT_COMMAND[@]}"