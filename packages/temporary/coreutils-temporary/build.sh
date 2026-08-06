#!/usr/bin/env bash

set -Eeuo pipefail

VEYR_CONFIGURE_ARGS=(
    --enable-install-program=hostname
    --enable-no-install-program=kill,uptime
)

veyr_post_install() {
    mkdir -p \
        "${VEYR_SYSROOT}/usr/sbin" \
        "${VEYR_SYSROOT}/usr/share/man/man8"

    mv \
        "${VEYR_SYSROOT}/usr/bin/chroot" \
        "${VEYR_SYSROOT}/usr/sbin/chroot"

    if [[ -f "${VEYR_SYSROOT}/usr/share/man/man1/chroot.1" ]]; then
        mv \
            "${VEYR_SYSROOT}/usr/share/man/man1/chroot.1" \
            "${VEYR_SYSROOT}/usr/share/man/man8/chroot.8"

        sed \
            -i 's/"1"/"8"/' \
            "${VEYR_SYSROOT}/usr/share/man/man8/chroot.8"
    fi
}

source "${VEYR_ROOT}/scripts/lib/temporary-autotools.sh"
