#!/usr/bin/bash
set -Eeuo pipefail

: "${VEYR_JOBS:?VEYR_JOBS is required}"

./configure \
    --prefix=/usr \
    --disable-static \
    --docdir=/usr/share/doc/mpdecimal-4.0.1

make -j"${VEYR_JOBS}"
make install
