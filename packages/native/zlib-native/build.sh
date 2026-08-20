#!/usr/bin/bash
set -Eeuo pipefail

: "${VEYR_JOBS:?VEYR_JOBS is required}"

./configure --prefix=/usr
make -j"${VEYR_JOBS}"
make install
