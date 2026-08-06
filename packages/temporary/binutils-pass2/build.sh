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

if sed -n '6031p' "${VEYR_SOURCE_DIR}/ltmain.sh" | grep -q '\$add_dir'; then
    sed \
        '6031s/$add_dir//' \
        -i \
        "${VEYR_SOURCE_DIR}/ltmain.sh"
else
    printf '[BINUTILS-PASS2] Note: ltmain.sh line 6031 no longer contains $add_dir; skipping the LFS 2.46.1 workaround.\n'
fi

OBJ_DIR="${VEYR_BUILD_DIR}/obj"

rm -rf "${OBJ_DIR}"
mkdir -p "${OBJ_DIR}"

cd "${OBJ_DIR}"

BUILD_TRIPLET="$("${VEYR_SOURCE_DIR}/config.guess")"

"${VEYR_SOURCE_DIR}/configure" \
    --prefix=/usr \
    --build="${BUILD_TRIPLET}" \
    --host="${VEYR_TARGET}" \
    --disable-nls \
    --enable-shared \
    --enable-gprofng=no \
    --disable-werror \
    --enable-64-bit-bfd \
    --enable-new-dtags \
    --enable-default-hash-style=gnu

make -j"${VEYR_JOBS}"

make \
    DESTDIR="${VEYR_SYSROOT}" \
    install

rm -f \
    "${VEYR_SYSROOT}"/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

printf '[BINUTILS-PASS2] Build complete\n'
