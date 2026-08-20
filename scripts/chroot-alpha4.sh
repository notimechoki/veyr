#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/chroot-mounts.sh"

ROOTFS="${BUILD_DIR}/images/base-alpha4/rootfs"

[[ -x "${ROOTFS}/usr/bin/bash" ]] \
    || die "Alpha.4 staging rootfs is missing. Run: ./veyr build --profile temporary-alpha4"

[[ -x "${ROOTFS}/usr/bin/python3" ]] \
    || die "Alpha.4 native tools are not built yet. Run: ./veyr build --profile temporary-alpha4"

veyr_init_sudo
veyr_prepare_chroot_mounts "${ROOTFS}"
trap veyr_cleanup_chroot_mounts EXIT INT TERM

if [[ "${1:-}" == "--" ]]; then
    shift
fi

if (( $# > 0 )); then
    CHROOT_COMMAND=("$@")
else
    CHROOT_COMMAND=(
        /usr/bin/bash
        --noprofile
        --norc
        -i
    )
fi

log "Entering Veyr alpha.4 chroot"

"${VEYR_SUDO[@]}" chroot "${ROOTFS}" \
    /usr/bin/env -i \
    HOME=/root \
    TERM="${TERM:-xterm}" \
    PS1='(veyr-alpha4) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin:/bin:/sbin \
    LC_ALL=POSIX \
    MAKEFLAGS="-j$(nproc)" \
    "${CHROOT_COMMAND[@]}"