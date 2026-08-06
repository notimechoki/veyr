#!/usr/bin/env bash

set -Eeuo pipefail

veyr_pre_configure() {
    sed \
        -i 's/extras//' \
        "${VEYR_SOURCE_DIR}/Makefile.in"
}

source "${VEYR_ROOT}/scripts/lib/temporary-autotools.sh"
