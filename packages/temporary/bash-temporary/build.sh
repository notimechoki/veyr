#!/usr/bin/env bash

set -Eeuo pipefail

VEYR_CONFIGURE_ARGS=(
    --without-bash-malloc
    "--docdir=/usr/share/doc/bash-${VEYR_PACKAGE_VERSION}"
)

VEYR_BUILD_GUESS="support/config.guess"

veyr_post_install() {
    ln -sfn \
        bash \
        "${VEYR_SYSROOT}/usr/bin/sh"
}

source "${VEYR_ROOT}/scripts/lib/temporary-autotools.sh"