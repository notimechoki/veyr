#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"
: "${VEYR_PACKAGE_OUT:?VEYR_PACKAGE_OUT is required}"
: "${VEYR_JOBS:?VEYR_JOBS is required}"

cd "${VEYR_SOURCE_DIR}"

rm -rf "${VEYR_PACKAGE_OUT}"
mkdir -p "${VEYR_PACKAGE_OUT}/rootfs"

printf '\n[BUSYBOX] Resetting source tree configuration\n'
make distclean

printf '[BUSYBOX] Creating default configuration\n'
make defconfig

enable_config() {
    local symbol="$1"

    if grep -q "^# ${symbol} is not set$" .config; then
        sed -i "s/^# ${symbol} is not set$/${symbol}=y/" .config
    elif grep -q "^${symbol}=" .config; then
        sed -i "s/^${symbol}=.*/${symbol}=y/" .config
    else
        printf '%s=y\n' "${symbol}" >> .config
    fi
}

disable_config() {
    local symbol="$1"

    if grep -q "^${symbol}=y$" .config; then
        sed -i "s/^${symbol}=y$/# ${symbol} is not set/" .config
    fi
}

printf '[BUSYBOX] Enabling static linking and alpha.3 early-boot applets\n'
enable_config CONFIG_STATIC
enable_config CONFIG_SWITCH_ROOT
enable_config CONFIG_MOUNT
enable_config CONFIG_UMOUNT
enable_config CONFIG_SLEEP
enable_config CONFIG_SETSID
enable_config CONFIG_CTTYHACK
enable_config CONFIG_FEATURE_MOUNT_FLAGS
enable_config CONFIG_SH_IS_ASH

printf '[BUSYBOX] Disabling tc applet incompatible with modern host UAPI headers\n'
disable_config CONFIG_TC
disable_config CONFIG_FEATURE_TC_INGRESS

printf '[BUSYBOX] Resolving configuration dependencies\n'

make oldconfig < <(yes '')

printf '[BUSYBOX] Verifying required configuration\n'

for required in \
    CONFIG_STATIC=y \
    CONFIG_SWITCH_ROOT=y \
    CONFIG_MOUNT=y \
    CONFIG_UMOUNT=y \
    CONFIG_SLEEP=y \
    CONFIG_SETSID=y \
    CONFIG_CTTYHACK=y; do

    grep -qx "${required}" .config || {
        echo "BusyBox required configuration is missing: ${required}" >&2
        exit 1
    }
done

if grep -qx 'CONFIG_TC=y' .config; then
    echo 'BusyBox tc applet must remain disabled for the current host UAPI.' >&2
    exit 1
fi

printf '[BUSYBOX] Building with %s jobs\n' "${VEYR_JOBS}"

make -j"${VEYR_JOBS}"

printf '[BUSYBOX] Installing temporary rootfs\n'

make \
    CONFIG_PREFIX="${VEYR_PACKAGE_OUT}/rootfs" \
    install

BUSYBOX_BIN="${VEYR_PACKAGE_OUT}/rootfs/bin/busybox"

[[ -x "${BUSYBOX_BIN}" ]] || {
    echo "BusyBox binary was not created: ${BUSYBOX_BIN}" >&2
    exit 1
}

FILE_INFO="$(
    file "${BUSYBOX_BIN}"
)"

printf '%s\n' "${FILE_INFO}"

if ! grep -qi 'statically linked' <<<"${FILE_INFO}"; then
    echo "BusyBox must be statically linked for the bootstrap initramfs." >&2
    exit 1
fi

APPLET_LIST="$(
    "${BUSYBOX_BIN}" --list
)"

for applet in \
    cttyhack \
    mount \
    setsid \
    switch_root \
    sh \
    sleep; do

    if ! grep -qx "${applet}" <<<"${APPLET_LIST}"; then
        echo "BusyBox is missing required applet: ${applet}" >&2
        exit 1
    fi

    printf '[BUSYBOX] Applet OK: %s\n' \
        "${applet}"
done

printf '[BUSYBOX] Build complete\n'