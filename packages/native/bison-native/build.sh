#!/usr/bin/bash
set -Eeuo pipefail

: "${VEYR_JOBS:?VEYR_JOBS is required}"

./configure \
    --prefix=/usr \
    --docdir=/usr/share/doc/bison-3.8.2

make -j"${VEYR_JOBS}"
make install