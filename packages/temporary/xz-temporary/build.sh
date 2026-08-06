#!/usr/bin/env bash

set -Eeuo pipefail

VEYR_CONFIGURE_ARGS=(
    --disable-static
    "--docdir=/usr/share/doc/xz-${VEYR_PACKAGE_VERSION}"
)

veyr_post_install() {
    rm -f \
        "${VEYR_SYSROOT}/usr/lib/liblzma.la"
}

source "${VEYR_ROOT}/scripts/lib/temporary-autotools.sh"
