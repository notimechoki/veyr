#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_ROOT:?VEYR_ROOT is required}"
: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"
: "${VEYR_BUILD_DIR:?VEYR_BUILD_DIR is required}"
: "${VEYR_JOBS:?VEYR_JOBS is required}"

source "${VEYR_ROOT}/scripts/lib/toolchain.sh"

ensure_veyr_layout

require_cross_tool ld
require_cross_tool as

for library in gmp mpfr mpc; do

    SRC="${VEYR_ROOT}/out/vendor/${library}"

    [[ -f "${SRC}/.veyr-source-ready" ]] || {
        echo "Missing prepared ${library} source tree: ${SRC}" >&2
        exit 1
    }

    rm -rf "${VEYR_SOURCE_DIR}/${library}"

    mkdir -p "${VEYR_SOURCE_DIR}/${library}"

    cp -a \
        "${SRC}/." \
        "${VEYR_SOURCE_DIR}/${library}/"

    rm -f \
        "${VEYR_SOURCE_DIR}/${library}/.veyr-source-ready"
done

case "$(uname -m)" in

    x86_64)

        sed \
            -e '/m64=/s/lib64/lib/' \
            -i.orig \
            "${VEYR_SOURCE_DIR}/gcc/config/i386/t-linux64"

        ;;

    *)

        echo "Veyr alpha.1 currently supports x86_64 hosts only." >&2
        exit 1

        ;;

esac

OBJ_DIR="${VEYR_BUILD_DIR}/obj"

rm -rf "${OBJ_DIR}"
mkdir -p "${OBJ_DIR}"

cd "${OBJ_DIR}"

printf '\n[GCC-CROSS] Building GCC %s for %s\n' \
    "${VEYR_PACKAGE_VERSION}" \
    "${VEYR_TARGET}"

"${VEYR_SOURCE_DIR}/configure" \
    --target="${VEYR_TARGET}" \
    --prefix="${VEYR_TOOLS}" \
    --with-glibc-version=2.44 \
    --with-sysroot="${VEYR_SYSROOT}" \
    --with-newlib \
    --without-headers \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-fixincludes \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-threads \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libvtv \
    --disable-libstdcxx \
    --enable-languages=c,c++

make -j"${VEYR_JOBS}"

make install

LIMITS_DIR="$(
    dirname "$("${VEYR_TARGET}-gcc" -print-libgcc-file-name)"
)/include"

mkdir -p "${LIMITS_DIR}"

cat \
    "${VEYR_SOURCE_DIR}/gcc/limitx.h" \
    "${VEYR_SOURCE_DIR}/gcc/glimits.h" \
    "${VEYR_SOURCE_DIR}/gcc/limity.h" \
    > "${LIMITS_DIR}/limits.h"

"${VEYR_TARGET}-gcc" --version | head -n 1

printf '[GCC-CROSS] Build complete\n'