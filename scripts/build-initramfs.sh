#!/usr/bin/env bash

set -Eeuo pipefail

BUILD_INITRAMFS_DIR="$(
    cd "$(dirname "${BASH_SOURCE[0]}")" \
    && pwd
)"

source "${BUILD_INITRAMFS_DIR}/lib/common.sh"

ensure_dirs

IMAGE_PROFILE="${1:-bootstrap}"

BUSYBOX_ROOT="${OUT_DIR}/packages/busybox/rootfs"
BUSYBOX_BIN="${BUSYBOX_ROOT}/bin/busybox"

ROOTFS_BUILD="${BUILD_DIR}/images/${IMAGE_PROFILE}/rootfs"
IMAGE_OUT="${OUT_DIR}/images/${IMAGE_PROFILE}"
INITRAMFS_FILE="${IMAGE_OUT}/initramfs.img"

[[ -x "${BUSYBOX_BIN}" ]] \
    || die "BusyBox package output not found. Run: ./veyr build busybox"

BUSYBOX_INFO="$(file "${BUSYBOX_BIN}")"

if ! grep -qi 'statically linked' <<<"${BUSYBOX_INFO}"; then
    die "BusyBox used by initramfs must be statically linked: ${BUSYBOX_INFO}"
fi

log "Preparing Veyr ${VEYR_VERSION} ${IMAGE_PROFILE} root filesystem"

rm -rf "${ROOTFS_BUILD}"

mkdir -p \
    "${ROOTFS_BUILD}" \
    "${IMAGE_OUT}"

if [[ "${IMAGE_PROFILE}" == "base-alpha2" ]]; then
    SYSROOT="${OUT_DIR}/sysroot"
    USERSPACE_TEST="${OUT_DIR}/tests/userspace/smoke.sh"
    SYSROOT_LOADER="${SYSROOT}/usr/lib/ld-linux-x86-64.so.2"

    [[ -x "${SYSROOT}/usr/bin/bash" ]] \
        || die "Temporary Bash not found. Run: ./veyr build --profile temporary-alpha2"

    [[ -x "${SYSROOT}/usr/bin/gcc" ]] \
        || die "GCC pass 2 not found. Run: ./veyr build --profile temporary-alpha2"

    [[ -x "${SYSROOT}/usr/bin/g++" ]] \
        || die "G++ pass 2 not found. Run: ./veyr build --profile temporary-alpha2"

    [[ -x "${SYSROOT}/usr/sbin/ldconfig" ]] \
        || die "Veyr ldconfig not found in sysroot"

    [[ -x "${USERSPACE_TEST}" ]] \
        || die "Userspace smoke test not prepared. Run: ./scripts/build-userspace-test.sh"

    [[ -d "${SYSROOT}/usr" ]] \
        || die "Veyr sysroot /usr tree is missing"

    [[ -e "${SYSROOT_LOADER}" ]] \
        || die "Veyr Glibc loader is missing: ${SYSROOT_LOADER}"

    log "Copying Veyr temporary userspace into alpha.2 initramfs"

    cp -a \
        "${SYSROOT}/usr" \
        "${ROOTFS_BUILD}/usr"

    ln -s usr/bin "${ROOTFS_BUILD}/bin"
    ln -s usr/lib "${ROOTFS_BUILD}/lib"
    ln -s usr/sbin "${ROOTFS_BUILD}/sbin"

    mkdir -p "${ROOTFS_BUILD}/lib64"

    cp -L \
        "${SYSROOT_LOADER}" \
        "${ROOTFS_BUILD}/lib64/ld-linux-x86-64.so.2"

    chmod 0755 \
        "${ROOTFS_BUILD}/lib64/ld-linux-x86-64.so.2"

    ln -sfn \
        ld-linux-x86-64.so.2 \
        "${ROOTFS_BUILD}/lib64/ld-lsb-x86-64.so.3"

    mkdir -p "${ROOTFS_BUILD}/usr/lib/veyr-tests"

    cp \
        "${USERSPACE_TEST}" \
        "${ROOTFS_BUILD}/usr/lib/veyr-tests/userspace-smoke.sh"

    chmod +x \
        "${ROOTFS_BUILD}/usr/lib/veyr-tests/userspace-smoke.sh"

    rm -rf \
        "${ROOTFS_BUILD}/usr/share/doc" \
        "${ROOTFS_BUILD}/usr/share/info" \
        "${ROOTFS_BUILD}/usr/share/man" \
        "${ROOTFS_BUILD}/usr/share/locale"
else
    cp -a \
        "${BUSYBOX_ROOT}/." \
        "${ROOTFS_BUILD}/"
fi

mkdir -p "${ROOTFS_BUILD}/usr/libexec"

cp \
    "${BUSYBOX_BIN}" \
    "${ROOTFS_BUILD}/usr/libexec/busybox"

chmod +x \
    "${ROOTFS_BUILD}/usr/libexec/busybox"

mkdir -p "${ROOTFS_BUILD}/rescue-bin"

RESCUE_APPLETS=(
    sh
    ash
    cat
    chmod
    clear
    cp
    dmesg
    echo
    env
    find
    grep
    head
    hostname
    ls
    mkdir
    mount
    mv
    poweroff
    printf
    ps
    pwd
    readlink
    reboot
    rm
    sed
    sleep
    sort
    stat
    tail
    test
    touch
    umount
    uname
    uniq
)

for applet in "${RESCUE_APPLETS[@]}"; do
    ln -sfn \
        ../usr/libexec/busybox \
        "${ROOTFS_BUILD}/rescue-bin/${applet}"
done

mkdir -p \
    "${ROOTFS_BUILD}/dev" \
    "${ROOTFS_BUILD}/proc" \
    "${ROOTFS_BUILD}/sys" \
    "${ROOTFS_BUILD}/run" \
    "${ROOTFS_BUILD}/tmp" \
    "${ROOTFS_BUILD}/root" \
    "${ROOTFS_BUILD}/etc"

chmod 1777 "${ROOTFS_BUILD}/tmp"

cp \
    "${ROOT_DIR}/rootfs/common/etc/motd" \
    "${ROOTFS_BUILD}/etc/motd"

sed \
    "s/@VERSION@/${VEYR_VERSION}/g" \
    "${ROOT_DIR}/rootfs/common/etc/os-release.in" \
    > "${ROOTFS_BUILD}/etc/os-release"

printf '%s\n' \
    "${IMAGE_PROFILE}" \
    > "${ROOTFS_BUILD}/etc/veyr-image-profile"

ROOT_SHELL="/bin/sh"

if [[ "${IMAGE_PROFILE}" == "base-alpha2" ]]; then
    ROOT_SHELL="/usr/bin/bash"
fi

cat > "${ROOTFS_BUILD}/etc/passwd" <<EOF_PASSWD
root:x:0:0:root:/root:${ROOT_SHELL}
EOF_PASSWD

cat > "${ROOTFS_BUILD}/etc/group" <<'EOF_GROUP'
root:x:0:
EOF_GROUP

cat > "${ROOTFS_BUILD}/etc/nsswitch.conf" <<'EOF_NSSWITCH'
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
EOF_NSSWITCH

cat > "${ROOTFS_BUILD}/etc/hosts" <<'EOF_HOSTS'
127.0.0.1 localhost
127.0.1.1 veyr
::1       localhost
EOF_HOSTS

if [[ "${IMAGE_PROFILE}" == "base-alpha2" ]]; then
    mkdir -p "${ROOTFS_BUILD}/etc/ld.so.conf.d"

    cat > "${ROOTFS_BUILD}/etc/ld.so.conf" <<'EOF_LDSO'
/usr/lib
include /etc/ld.so.conf.d/*.conf
EOF_LDSO

    TARGET_LDCONFIG="${ROOTFS_BUILD}/usr/sbin/ldconfig"
    LDCONFIG_INFO="$(file "${TARGET_LDCONFIG}")"

    printf '[VEYR] alpha.2 ldconfig: %s\n' \
        "${LDCONFIG_INFO}"

    if ! grep -Eqi 'static|statically linked' <<<"${LDCONFIG_INFO}"; then
        die "Veyr ldconfig must be static for host-side rootfs cache generation"
    fi

    "${TARGET_LDCONFIG}" \
        -r "${ROOTFS_BUILD}"

    [[ -s "${ROOTFS_BUILD}/etc/ld.so.cache" ]] \
        || die "Veyr ldconfig did not create /etc/ld.so.cache"

    success "Dynamic loader cache created for alpha.2"
fi

cp \
    "${ROOT_DIR}/initramfs/init" \
    "${ROOTFS_BUILD}/init"

cp \
    "${ROOT_DIR}/initramfs/rescue-init" \
    "${ROOTFS_BUILD}/rescue-init"

chmod +x \
    "${ROOTFS_BUILD}/init" \
    "${ROOTFS_BUILD}/rescue-init"

mkdir -p "${ROOTFS_BUILD}/usr/sbin"

ln -sfn \
    ../libexec/busybox \
    "${ROOTFS_BUILD}/usr/sbin/poweroff"

ln -sfn \
    ../libexec/busybox \
    "${ROOTFS_BUILD}/usr/sbin/reboot"

if [[ "${IMAGE_PROFILE}" == "base-alpha1" ]]; then
    SYSROOT="${OUT_DIR}/sysroot"
    TEST_BINARY="${OUT_DIR}/tests/toolchain/veyr-toolchain-test"

    [[ -e "${SYSROOT}/usr/lib/libc.so.6" ]] \
        || die "Veyr bootstrap Glibc not found. Run: ./veyr build --profile base-alpha1"

    [[ -e "${SYSROOT}/usr/lib/ld-linux-x86-64.so.2" ]] \
        || die "Veyr Glibc loader not found."

    [[ -x "${TEST_BINARY}" ]] \
        || die "Toolchain VM test binary not found. Run: ./scripts/build-toolchain-test.sh"

    log "Adding Veyr Glibc and cross-toolchain test binary to alpha.1 initramfs"

    mkdir -p \
        "${ROOTFS_BUILD}/usr/bin" \
        "${ROOTFS_BUILD}/usr/lib" \
        "${ROOTFS_BUILD}/lib64"

    cp -L \
        "${SYSROOT}/usr/lib/libc.so.6" \
        "${ROOTFS_BUILD}/usr/lib/libc.so.6"

    cp -L \
        "${SYSROOT}/usr/lib/ld-linux-x86-64.so.2" \
        "${ROOTFS_BUILD}/usr/lib/ld-linux-x86-64.so.2"

    cp -L \
        "${SYSROOT}/usr/lib/ld-linux-x86-64.so.2" \
        "${ROOTFS_BUILD}/lib64/ld-linux-x86-64.so.2"

    chmod 0755 \
        "${ROOTFS_BUILD}/lib64/ld-linux-x86-64.so.2"

    cp \
        "${TEST_BINARY}" \
        "${ROOTFS_BUILD}/usr/bin/veyr-toolchain-test"

    chmod +x \
        "${ROOTFS_BUILD}/usr/bin/veyr-toolchain-test"
fi

if [[ "${IMAGE_PROFILE}" == "base-alpha2" ]]; then
    VALIDATOR="${BUILD_INITRAMFS_DIR}/validate-alpha2-rootfs.sh"

    [[ -x "${VALIDATOR}" ]] \
        || die "Alpha.2 rootfs validator is missing or not executable: ${VALIDATOR}"

    "${VALIDATOR}" "${ROOTFS_BUILD}"
fi

log "Creating compressed initramfs"

(
    cd "${ROOTFS_BUILD}"

    find . -print0 \
        | sort -z \
        | cpio \
            --null \
            --create \
            --format=newc \
            --owner=0:0 \
        | gzip -9 \
        > "${INITRAMFS_FILE}"
)

[[ -s "${INITRAMFS_FILE}" ]] \
    || die "Initramfs was not created"

success "Initramfs created: ${INITRAMFS_FILE}"

du -h "${INITRAMFS_FILE}"