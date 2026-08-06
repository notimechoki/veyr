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
require_cross_tool g++

HOST_BUILD="${VEYR_BUILD_DIR}/host-tic"

rm -rf "${HOST_BUILD}"
mkdir -p "${HOST_BUILD}"

pushd "${HOST_BUILD}" >/dev/null

"${VEYR_SOURCE_DIR}/configure" \
    --prefix="${VEYR_TOOLS}" \
    AWK=gawk

make -C include
make -C progs tic

install -Dm755 \
    progs/tic \
    "${VEYR_TOOLS}/bin/tic"

popd >/dev/null

cd "${VEYR_SOURCE_DIR}"

./configure \
    --prefix=/usr \
    --host="${VEYR_TARGET}" \
    --build="$(./config.guess)" \
    --mandir=/usr/share/man \
    --with-manpage-format=normal \
    --with-shared \
    --without-normal \
    --with-cxx-shared \
    --without-debug \
    --without-ada \
    --disable-stripping \
    AWK=gawk

make -j"${VEYR_JOBS}"

make \
    DESTDIR="${VEYR_SYSROOT}" \
    install

ln -sfn \
    libncursesw.so \
    "${VEYR_SYSROOT}/usr/lib/libncurses.so"

sed \
    -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i \
    "${VEYR_SYSROOT}/usr/include/curses.h"

printf '[NCURSES-TEMPORARY] Build complete\n'
