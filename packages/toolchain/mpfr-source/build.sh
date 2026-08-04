#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_ROOT:?VEYR_ROOT is required}"
: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"

DEST="${VEYR_ROOT}/out/vendor/mpfr"

rm -rf "${DEST}"
mkdir -p "${DEST}"

cp -a "${VEYR_SOURCE_DIR}/." "${DEST}/"

printf '%s\n' "${VEYR_PACKAGE_VERSION}" \
    > "${DEST}/.veyr-source-ready"

printf '[MPFR-SOURCE] Prepared %s\n' "${DEST}"