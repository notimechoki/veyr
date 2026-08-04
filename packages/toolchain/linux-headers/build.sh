#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_ROOT:?VEYR_ROOT is required}"
: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"

source "${VEYR_ROOT}/scripts/lib/toolchain.sh"

ensure_veyr_layout

cd "${VEYR_SOURCE_DIR}"

printf '\n[LINUX-HEADERS] Cleaning kernel source tree\n'

make mrproper

printf '[LINUX-HEADERS] Generating sanitized userspace API headers\n'

make headers

find usr/include \
    -type f \
    ! -name '*.h' \
    -delete

mkdir -p "${VEYR_SYSROOT}/usr/include"

cp -a \
    usr/include/. \
    "${VEYR_SYSROOT}/usr/include/"

printf '[LINUX-HEADERS] Installed into %s/usr/include\n' \
    "${VEYR_SYSROOT}"