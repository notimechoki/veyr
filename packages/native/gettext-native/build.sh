#!/usr/bin/bash
set -Eeuo pipefail

: "${VEYR_JOBS:?VEYR_JOBS is required}"

./configure --disable-shared
make -j"${VEYR_JOBS}"

install -m 0755 \
    gettext-tools/src/msgfmt \
    gettext-tools/src/msgmerge \
    gettext-tools/src/xgettext \
    /usr/bin/