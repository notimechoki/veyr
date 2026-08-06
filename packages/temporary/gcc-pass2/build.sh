#!/usr/bin/env bash

set -Eeuo pipefail

: "${VEYR_ROOT:?VEYR_ROOT is required}"
: "${VEYR_SOURCE_DIR:?VEYR_SOURCE_DIR is required}"
: "${VEYR_BUILD_DIR:?VEYR_BUILD_DIR is required}"
: "${VEYR_JOBS:?VEYR_JOBS is required}"

source "${VEYR_ROOT}/scripts/lib/toolchain.sh"

ensure_veyr_layout
enable_veyr_config_site
require_cross_tool gcc
require_cross_tool g++

for library in gmp mpfr mpc; do
    SRC="${VEYR_ROOT}/out/vendor/${library}"

    [[ -f "${SRC}/.veyr-source-ready" ]] || {
        echo "Missing prepared ${library} source tree: ${SRC}" >&2
        exit 1
    }

    rm -rf "${VEYR_SOURCE_DIR:?}/${library}"
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
        echo "Veyr alpha.2 currently supports x86_64 hosts only." >&2
        exit 1
        ;;
esac

OBJ_DIR="${VEYR_BUILD_DIR}/obj"

rm -rf "${OBJ_DIR}"
mkdir -p "${OBJ_DIR}"

cd "${OBJ_DIR}"

BUILD_TRIPLET="$("${VEYR_SOURCE_DIR}/config.guess")"

unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS

"${VEYR_SOURCE_DIR}/configure" \
    --build="${BUILD_TRIPLET}" \
    --host="${VEYR_TARGET}" \
    --target="${VEYR_TARGET}" \
    --prefix=/usr \
    --with-build-sysroot="${VEYR_SYSROOT}" \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-fixincludes \
    --disable-nls \
    --disable-multilib \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libsanitizer \
    --disable-libssp \
    --disable-libvtv \
    --enable-languages=c,c++ \
    LDFLAGS_FOR_TARGET="-L${PWD}/${VEYR_TARGET}/libgcc" \
    target_configargs=gcc_cv_target_thread_file=posix

make -j"${VEYR_JOBS}"

make \
    DESTDIR="${VEYR_SYSROOT}" \
    install

ln -sfn \
    gcc \
    "${VEYR_SYSROOT}/usr/bin/cc"

printf '[GCC-PASS2] Build complete\n'
