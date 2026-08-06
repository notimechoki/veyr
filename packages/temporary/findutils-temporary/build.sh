#!/usr/bin/env bash

set -Eeuo pipefail

VEYR_CONFIGURE_ARGS=(
    --localstatedir=/var/lib/locate
)

source "${VEYR_ROOT}/scripts/lib/temporary-autotools.sh"
