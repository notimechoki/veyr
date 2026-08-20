#!/usr/bin/env bash

# Shared host-side mount helpers for Veyr chroot workflows.
# This file is sourced by run-chroot-package.sh and chroot-alpha4.sh.

VEYR_CHROOT_MOUNTS=()

veyr_init_sudo() {
    if (( EUID == 0 )); then
        VEYR_SUDO=()
    else
        VEYR_SUDO=(sudo)
    fi
}

veyr_mount_if_needed() {
    local type="$1"
    local source="$2"
    local target="$3"
    shift 3

    if mountpoint -q "${target}"; then
        return 0
    fi

    "${VEYR_SUDO[@]}" mount -t "${type}" "$@" "${source}" "${target}"
    VEYR_CHROOT_MOUNTS+=("${target}")
}

veyr_bind_if_needed() {
    local source="$1"
    local target="$2"

    if mountpoint -q "${target}"; then
        return 0
    fi

    "${VEYR_SUDO[@]}" mount --bind "${source}" "${target}"
    VEYR_CHROOT_MOUNTS+=("${target}")
}

veyr_prepare_chroot_mounts() {
    local rootfs="$1"

    mkdir -p \
        "${rootfs}/dev" \
        "${rootfs}/dev/pts" \
        "${rootfs}/proc" \
        "${rootfs}/sys" \
        "${rootfs}/run"

    veyr_bind_if_needed /dev "${rootfs}/dev"

    if ! mountpoint -q "${rootfs}/dev/pts"; then
        "${VEYR_SUDO[@]}" mount -t devpts devpts "${rootfs}/dev/pts"
        VEYR_CHROOT_MOUNTS+=("${rootfs}/dev/pts")
    fi

    if ! mountpoint -q "${rootfs}/proc"; then
        "${VEYR_SUDO[@]}" mount -t proc proc "${rootfs}/proc"
        VEYR_CHROOT_MOUNTS+=("${rootfs}/proc")
    fi

    if ! mountpoint -q "${rootfs}/sys"; then
        "${VEYR_SUDO[@]}" mount -t sysfs sysfs "${rootfs}/sys"
        VEYR_CHROOT_MOUNTS+=("${rootfs}/sys")
    fi

    if ! mountpoint -q "${rootfs}/run"; then
        "${VEYR_SUDO[@]}" mount -t tmpfs tmpfs "${rootfs}/run"
        VEYR_CHROOT_MOUNTS+=("${rootfs}/run")
    fi
}

veyr_cleanup_chroot_mounts() {
    local index

    set +e

    for (( index=${#VEYR_CHROOT_MOUNTS[@]}-1; index>=0; index-- )); do
        "${VEYR_SUDO[@]}" umount -l "${VEYR_CHROOT_MOUNTS[index]}" \
            2>/dev/null || true
    done

    VEYR_CHROOT_MOUNTS=()
}