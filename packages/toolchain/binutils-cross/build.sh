#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_ROOT:?VEYR_ROOT is required}"
: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"
: "${VEYR_BUILD_DIR:?VEYR_BUILD_DIR is required}"
: "${VEYR_JOBS:?VEYR_JOBS is required}"

source "${VEYR_ROOT}/scripts/lib/toolchain.sh"

ensure_veyr_layout

OBJ_DIR="${VEYR_BUILD_DIR}/obj"

rm -rf "${OBJ_DIR}"
mkdir -p "${OBJ_DIR}"

cd "${OBJ_DIR}"

printf '\n[BINUTILS-CROSS] Target: %s\n' "${VEYR_TARGET}"
printf '[BINUTILS-CROSS] Sysroot: %s\n' "${VEYR_SYSROOT}"
printf '[BINUTILS-CROSS] Tools prefix: %s\n' "${VEYR_TOOLS}"

"${VEYR_SOURCE_DIR}/configure" \
    --prefix="${VEYR_TOOLS}" \
    --with-sysroot="${VEYR_SYSROOT}" \
    --target="${VEYR_TARGET}" \
    --disable-nls \
    --enable-gprofng=no \
    --disable-werror \
    --enable-new-dtags \
    --enable-default-hash-style=gnu

make -j"${VEYR_JOBS}"
make install

"${VEYR_TARGET}-ld" --version | head -n 1
"${VEYR_TARGET}-as" --version | head -n 1

printf '[BINUTILS-CROSS] Build complete\n'