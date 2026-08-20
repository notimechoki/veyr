#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/chroot-mounts.sh"

[[ $# -eq 7 ]] || die \
    "Usage: run-chroot-package.sh ROOTFS SOURCE_DIR BUILD_SCRIPT NAME VERSION JOBS PROTOCOL"

ROOTFS="$1"
SOURCE_DIR="$2"
BUILD_SCRIPT="$3"
PACKAGE_NAME="$4"
PACKAGE_VERSION="$5"
JOBS="$6"
EXTRA_GUARD="$7"

# The seventh argument is an explicit protocol marker supplied by Forge.
[[ "${EXTRA_GUARD}" == "veyr-chroot-v1" ]] \
    || die "Invalid chroot runner invocation"

ROOTFS="$(realpath "${ROOTFS}")"
SOURCE_DIR="$(realpath "${SOURCE_DIR}")"
BUILD_SCRIPT="$(realpath "${BUILD_SCRIPT}")"

[[ -d "${ROOTFS}" ]] || die "Chroot root does not exist: ${ROOTFS}"
[[ -d "${SOURCE_DIR}" ]] || die "Chroot source directory does not exist: ${SOURCE_DIR}"
[[ -f "${BUILD_SCRIPT}" ]] || die "Package build script does not exist: ${BUILD_SCRIPT}"

case "${SOURCE_DIR}/" in
    "${ROOTFS}/"*) ;;
    *) die "Source directory is outside the configured chroot root" ;;
esac

[[ -x "${ROOTFS}/usr/bin/bash" ]] || die "Veyr Bash is missing in chroot"
[[ -x "${ROOTFS}/usr/bin/gcc" ]] || die "Veyr GCC is missing in chroot"
[[ -x "${ROOTFS}/usr/bin/make" ]] || die "Veyr Make is missing in chroot"

CHROOT_SOURCE="/${SOURCE_DIR#${ROOTFS}/}"
CHROOT_SCRIPT_DIR=/tmp/veyr-build
CHROOT_SCRIPT="${CHROOT_SCRIPT_DIR}/${PACKAGE_NAME}.sh"
HOST_SCRIPT_DIR="${ROOTFS}${CHROOT_SCRIPT_DIR}"
HOST_SCRIPT="${ROOTFS}${CHROOT_SCRIPT}"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"

mkdir -p "${HOST_SCRIPT_DIR}"
cp "${BUILD_SCRIPT}" "${HOST_SCRIPT}"
chmod 0755 "${HOST_SCRIPT}"

veyr_init_sudo

cleanup() {
    local status=$?

    veyr_cleanup_chroot_mounts

    "${VEYR_SUDO[@]}" chown -R \
        "${HOST_UID}:${HOST_GID}" \
        "${SOURCE_DIR}" \
        "${HOST_SCRIPT_DIR}" \
        2>/dev/null || true

    exit "${status}"
}

trap cleanup EXIT INT TERM

log "Preparing virtual filesystems for ${PACKAGE_NAME}"
veyr_prepare_chroot_mounts "${ROOTFS}"

log "Native Veyr chroot build: ${PACKAGE_NAME} ${PACKAGE_VERSION}"

"${VEYR_SUDO[@]}" chroot "${ROOTFS}" \
    /usr/bin/env -i \
    HOME=/root \
    TERM="${TERM:-dumb}" \
    PATH=/usr/bin:/usr/sbin:/bin:/sbin \
    LC_ALL=POSIX \
    MAKEFLAGS="-j${JOBS}" \
    VEYR_VERSION="${VEYR_VERSION:-unknown}" \
    VEYR_ARCH="${VEYR_ARCH:-x86_64}" \
    VEYR_BUILD_ENVIRONMENT=chroot \
    VEYR_PACKAGE_NAME="${PACKAGE_NAME}" \
    VEYR_PACKAGE_VERSION="${PACKAGE_VERSION}" \
    VEYR_SOURCE_DIR="${CHROOT_SOURCE}" \
    VEYR_PACKAGE_OUT="/tmp/veyr-package-out/${PACKAGE_NAME}" \
    VEYR_JOBS="${JOBS}" \
    /usr/bin/bash --noprofile --norc -c '
        set -Eeuo pipefail
        mkdir -p "$VEYR_PACKAGE_OUT"
        cd "$VEYR_SOURCE_DIR"
        exec "/tmp/veyr-build/${VEYR_PACKAGE_NAME}.sh"
    '

log "Refreshing Veyr dynamic loader cache"
"${VEYR_SUDO[@]}" chroot "${ROOTFS}" /usr/sbin/ldconfig

log "Recording native-build provenance for ${PACKAGE_NAME}"

"${VEYR_SUDO[@]}" chroot "${ROOTFS}" \
    /usr/bin/env -i \
    PATH=/usr/bin:/usr/sbin:/bin:/sbin \
    LC_ALL=POSIX \
    VEYR_PACKAGE_NAME="${PACKAGE_NAME}" \
    VEYR_PACKAGE_VERSION="${PACKAGE_VERSION}" \
    /usr/bin/bash --noprofile --norc -c '
        set -Eeuo pipefail

        marker_dir=/usr/lib/veyr/native-build
        marker="${marker_dir}/${VEYR_PACKAGE_NAME}.stamp"
        compiler="$(gcc -dumpmachine)"

        mkdir -p "$marker_dir"

        cat > "$marker" <<EOF_MARKER
package=${VEYR_PACKAGE_NAME}
version=${VEYR_PACKAGE_VERSION}
environment=chroot
compiler=${compiler}
EOF_MARKER
    '

success "Native chroot package complete: ${PACKAGE_NAME} ${PACKAGE_VERSION}"