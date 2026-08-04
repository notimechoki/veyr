#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_ROOT:?VEYR_ROOT is required}"
: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"
: "${VEYR_BUILD_DIR:?VEYR_BUILD_DIR is required}"
: "${VEYR_JOBS:?VEYR_JOBS is required}"

if [[ "${EUID}" -eq 0 ]]; then
    echo "Refusing to build/install bootstrap Glibc as root." >&2
    exit 1
fi

source "${VEYR_ROOT}/scripts/lib/toolchain.sh"

ensure_veyr_layout

require_cross_tool gcc
require_cross_tool ld

ln -sfn \
    ../lib/ld-linux-x86-64.so.2 \
    "${VEYR_SYSROOT}/lib64/ld-linux-x86-64.so.2"

ln -sfn \
    ../lib/ld-linux-x86-64.so.2 \
    "${VEYR_SYSROOT}/lib64/ld-lsb-x86-64.so.3"

OBJ_DIR="${VEYR_BUILD_DIR}/obj"

rm -rf "${OBJ_DIR}"
mkdir -p "${OBJ_DIR}"

cd "${OBJ_DIR}"

echo 'rootsbindir=/usr/sbin' > configparms

BUILD_TRIPLET="$("${VEYR_SOURCE_DIR}/scripts/config.guess")"

printf '\n[GLIBC-BOOTSTRAP] Build: %s\n' "${BUILD_TRIPLET}"
printf '[GLIBC-BOOTSTRAP] Host/target: %s\n' "${VEYR_TARGET}"
printf '[GLIBC-BOOTSTRAP] Sysroot: %s\n' "${VEYR_SYSROOT}"

"${VEYR_SOURCE_DIR}/configure" \
    --prefix=/usr \
    --host="${VEYR_TARGET}" \
    --build="${BUILD_TRIPLET}" \
    --disable-nscd \
    libc_cv_slibdir=/usr/lib \
    --enable-kernel="${VEYR_MIN_KERNEL}"

if ! make -j"${VEYR_JOBS}"; then

    echo "Parallel Glibc build failed; retrying with -j1." >&2

    make -j1
fi

make \
    DESTDIR="${VEYR_SYSROOT}" \
    install

if [[ -f "${VEYR_SYSROOT}/usr/bin/ldd" ]]; then

    sed \
        '/RTLDLIST=/s@/usr@@g' \
        -i \
        "${VEYR_SYSROOT}/usr/bin/ldd"

fi

[[ -e "${VEYR_SYSROOT}/usr/lib/libc.so.6" ]] || {
    echo "Glibc libc.so.6 was not installed." >&2
    exit 1
}

[[ -e "${VEYR_SYSROOT}/usr/lib/ld-linux-x86-64.so.2" ]] || {
    echo "Glibc dynamic loader was not installed." >&2
    exit 1
}

printf '[GLIBC-BOOTSTRAP] Build complete\n'