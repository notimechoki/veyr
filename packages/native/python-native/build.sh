#!/usr/bin/bash
set -Eeuo pipefail

: "${VEYR_JOBS:?VEYR_JOBS is required}"

./configure \
    --prefix=/usr \
    --enable-shared \
    --without-ensurepip \
    --without-static-libpython

make -j"${VEYR_JOBS}"
make install
