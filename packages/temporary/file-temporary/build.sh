#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_ROOT:?VEYR_ROOT is required}"
: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"
: "${VEYR_BUILD_DIR:?VEYR_BUILD_DIR is required}"
: "${VEYR_JOBS:?VEYR_JOBS is required}"

source "${VEYR_ROOT}/scripts/lib/toolchain.sh"

ensure_veyr_layout
enable_veyr_config_site
require_cross_tool gcc

HOST_BUILD="${VEYR_BUILD_DIR}/host-file"

rm -rf "${HOST_BUILD}"
mkdir -p "${HOST_BUILD}"

pushd "${HOST_BUILD}" >/dev/null

"${VEYR_SOURCE_DIR}/configure" \
    --disable-bzlib \
    --disable-libseccomp \
    --disable-xzlib \
    --disable-zlib

make -j"${VEYR_JOBS}"

popd >/dev/null

cd "${VEYR_SOURCE_DIR}"

./configure \
    --prefix=/usr \
    --host="${VEYR_TARGET}" \
    --build="$(./config.guess)"

make \
    -j"${VEYR_JOBS}" \
    FILE_COMPILE="${HOST_BUILD}/src/file"

make \
    DESTDIR="${VEYR_SYSROOT}" \
    install

rm -f \
    "${VEYR_SYSROOT}/usr/lib/libmagic.la"

printf '[FILE-TEMPORARY] Build complete\n'
