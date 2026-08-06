#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_ROOT:?VEYR_ROOT is required}"
: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"
: "${VEYR_JOBS:?VEYR_JOBS is required}"

source "${VEYR_ROOT}/scripts/lib/toolchain.sh"

ensure_veyr_layout
require_cross_tool gcc

VEYR_BUILD_GUESS="${VEYR_BUILD_GUESS:-build-aux/config.guess}"

if declare -F veyr_pre_configure >/dev/null 2>&1; then
    veyr_pre_configure
fi

enable_veyr_config_site

BUILD_GUESS_PATH="${VEYR_SOURCE_DIR}/${VEYR_BUILD_GUESS}"

if [[ ! -f "${BUILD_GUESS_PATH}" ]]; then
    echo "Build triplet helper not found: ${BUILD_GUESS_PATH}" >&2
    exit 1
fi

BUILD_TRIPLET="$(
    sh "${BUILD_GUESS_PATH}"
)"

if [[ -z "${BUILD_TRIPLET}" ]]; then
    echo "Build triplet helper returned an empty value: ${BUILD_GUESS_PATH}" >&2
    exit 1
fi

cd "${VEYR_SOURCE_DIR}"

CONFIGURE_ARGS=(
    --prefix=/usr
    --host="${VEYR_TARGET}"
    --build="${BUILD_TRIPLET}"
)

if declare -p VEYR_CONFIGURE_ARGS >/dev/null 2>&1; then
    CONFIGURE_ARGS+=(
        "${VEYR_CONFIGURE_ARGS[@]}"
    )
fi

printf '\n[%s] Build triplet: %s\n' \
    "${VEYR_PACKAGE_NAME^^}" \
    "${BUILD_TRIPLET}"

printf '[%s] Host triplet: %s\n' \
    "${VEYR_PACKAGE_NAME^^}" \
    "${VEYR_TARGET}"

printf '[%s] Configuring\n' \
    "${VEYR_PACKAGE_NAME^^}"

./configure "${CONFIGURE_ARGS[@]}"

printf '[%s] Building with %s jobs\n' \
    "${VEYR_PACKAGE_NAME^^}" \
    "${VEYR_JOBS}"

make -j"${VEYR_JOBS}"

if declare -F veyr_pre_install >/dev/null 2>&1; then
    veyr_pre_install
fi

printf '[%s] Installing into %s\n' \
    "${VEYR_PACKAGE_NAME^^}" \
    "${VEYR_SYSROOT}"

make \
    DESTDIR="${VEYR_SYSROOT}" \
    install

if declare -F veyr_post_install >/dev/null 2>&1; then
    veyr_post_install
fi

printf '[%s] Build complete\n' \
    "${VEYR_PACKAGE_NAME^^}"