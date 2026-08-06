#!/usr/bin/env bash

set -Eeuo pipefail

VEYR_CONFIGURE_ARGS=(
    gl_cv_func_strcasecmp_works=yes
)

VEYR_BUILD_GUESS="build-aux/config.guess"

source "${VEYR_ROOT}/scripts/lib/temporary-autotools.sh"
