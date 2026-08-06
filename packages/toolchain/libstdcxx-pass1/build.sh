#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_ROOT:?VEYR_ROOT is required}"
: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"
: "${VEYR_BUILD_DIR:?VEYR_BUILD_DIR is required}"
: "${VEYR_JOBS:?VEYR_JOBS is required}"

source "${VEYR_ROOT}/scripts/lib/toolchain.sh"

ensure_veyr_layout
require_cross_tool gcc
require_cross_tool g++

OBJ_DIR="${VEYR_BUILD_DIR}/obj"

rm -rf "${OBJ_DIR}"
mkdir -p "${OBJ_DIR}"

cd "${OBJ_DIR}"

BUILD_TRIPLET="$("${VEYR_SOURCE_DIR}/config.guess")"

printf '\n[LIBSTDCXX-PASS1] Building target Libstdc++ %s\n' \
    "${VEYR_PACKAGE_VERSION}"

"${VEYR_SOURCE_DIR}/libstdc++-v3/configure" \
    --host="${VEYR_TARGET}" \
    --build="${BUILD_TRIPLET}" \
    --prefix=/usr \
    --disable-multilib \
    --disable-nls \
    --disable-libstdcxx-pch \
    --with-gxx-include-dir="/tools/${VEYR_TARGET}/include/c++/${VEYR_PACKAGE_VERSION}"

make -j"${VEYR_JOBS}"

make \
    DESTDIR="${VEYR_SYSROOT}" \
    install

rm -f \
    "${VEYR_SYSROOT}/usr/lib/libstdc++.la" \
    "${VEYR_SYSROOT}/usr/lib/libstdc++exp.la" \
    "${VEYR_SYSROOT}/usr/lib/libstdc++fs.la" \
    "${VEYR_SYSROOT}/usr/lib/libsupc++.la"

printf '[LIBSTDCXX-PASS1] Build complete\n'