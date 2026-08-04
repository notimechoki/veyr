#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"
: "${VEYR_PACKAGE_OUT:?VEYR_PACKAGE_OUT is required}"
: "${VEYR_JOBS:?VEYR_JOBS is required}"

cd "${VEYR_SOURCE_DIR}"

rm -rf "${VEYR_PACKAGE_OUT}"
mkdir -p "${VEYR_PACKAGE_OUT}/rootfs"

printf '\n[BUSYBOX] Creating default configuration\n'
make defconfig

printf '[BUSYBOX] Enabling static linking\n'
if grep -q '^# CONFIG_STATIC is not set' .config; then
    sed -i 's/^# CONFIG_STATIC is not set$/CONFIG_STATIC=y/' .config
elif grep -q '^CONFIG_STATIC=' .config; then
    sed -i 's/^CONFIG_STATIC=.*/CONFIG_STATIC=y/' .config
else
    echo 'CONFIG_STATIC=y' >> .config
fi

printf '[BUSYBOX] Disabling tc applet incompatible with modern host UAPI headers\n'
if grep -q '^CONFIG_TC=y' .config; then
    sed -i 's/^CONFIG_TC=y$/# CONFIG_TC is not set/' .config
fi

if grep -q '^CONFIG_FEATURE_TC_INGRESS=y' .config; then
    sed -i 's/^CONFIG_FEATURE_TC_INGRESS=y$/# CONFIG_FEATURE_TC_INGRESS is not set/' .config
fi

printf '[BUSYBOX] Building with %s jobs\n' "${VEYR_JOBS}"
make -j"${VEYR_JOBS}"

printf '[BUSYBOX] Installing temporary rootfs\n'
make CONFIG_PREFIX="${VEYR_PACKAGE_OUT}/rootfs" install

BUSYBOX_BIN="${VEYR_PACKAGE_OUT}/rootfs/bin/busybox"

[[ -x "${BUSYBOX_BIN}" ]] || {
    echo "BusyBox binary was not created: ${BUSYBOX_BIN}" >&2
    exit 1
}

FILE_INFO="$(file "${BUSYBOX_BIN}")"
printf '%s\n' "${FILE_INFO}"

if ! grep -qi 'statically linked' <<<"${FILE_INFO}"; then
    echo "BusyBox must be statically linked for the bootstrap initramfs." >&2
    exit 1
fi

printf '[BUSYBOX] Build complete\n'