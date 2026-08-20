#!/usr/bin/bash
set -Eeuo pipefail

: "${VEYR_JOBS:?VEYR_JOBS is required}"

mkdir -p /var/lib/hwclock

./configure \
    --libdir=/usr/lib \
    --runstatedir=/run \
    --disable-chfn-chsh \
    --disable-login \
    --disable-nologin \
    --disable-su \
    --disable-setpriv \
    --disable-runuser \
    --disable-pylibmount \
    --disable-static \
    --disable-liblastlog2 \
    --without-python \
    ADJTIME_PATH=/var/lib/hwclock/adjtime \
    --docdir=/usr/share/doc/util-linux-2.42.2

make -j"${VEYR_JOBS}"
make install
