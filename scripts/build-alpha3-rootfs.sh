#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

ensure_dirs

PROFILE=base-alpha3

SYSROOT="${OUT_DIR}/sysroot"
BUSYBOX_BIN="${OUT_DIR}/packages/busybox/rootfs/bin/busybox"

ROOTFS_BUILD="${BUILD_DIR}/images/${PROFILE}/rootfs"

IMAGE_OUT="${OUT_DIR}/images/${PROFILE}"
ROOTFS_IMAGE="${IMAGE_OUT}/veyr-rootfs.ext4"

ROOTFS_SIZE_MB="${VEYR_ALPHA3_ROOTFS_MB:-8192}"

SMOKE_TEST="${ROOT_DIR}/tests/rootfs-alpha3/smoke.sh"
ROOT_INIT="${ROOT_DIR}/rootfs/alpha3/init"

require_command truncate
require_command mkfs.ext4
require_command e2fsck
require_command debugfs
require_command file

[[ -d "${SYSROOT}/usr" ]] \
    || die "Temporary Veyr sysroot is missing. Run: ./veyr build --profile temporary-alpha2"

[[ -x "${SYSROOT}/usr/bin/bash" ]] \
    || die "Temporary Bash is missing from sysroot"

[[ -x "${SYSROOT}/usr/bin/gcc" ]] \
    || die "GCC pass 2 is missing from sysroot"

[[ -x "${SYSROOT}/usr/bin/g++" ]] \
    || die "G++ pass 2 is missing from sysroot"

[[ -x "${SYSROOT}/usr/sbin/ldconfig" ]] \
    || die "Static Veyr ldconfig is missing from sysroot"

[[ -x "${BUSYBOX_BIN}" ]] \
    || die "Static BusyBox output is missing"

[[ -x "${SMOKE_TEST}" ]] \
    || die "Alpha.3 runtime smoke test is missing or not executable"

[[ -x "${ROOT_INIT}" ]] \
    || die "Alpha.3 root init is missing or not executable"

BUSYBOX_INFO="$(file "${BUSYBOX_BIN}")"

if ! grep -qi 'statically linked' <<<"${BUSYBOX_INFO}"; then
    die "Alpha.3 rescue BusyBox must be statically linked: ${BUSYBOX_INFO}"
fi

log "Preparing alpha.3 disk root staging tree"

rm -rf "${ROOTFS_BUILD}"

mkdir -p \
    "${ROOTFS_BUILD}" \
    "${IMAGE_OUT}"

cp -a \
    "${SYSROOT}/usr" \
    "${ROOTFS_BUILD}/usr"

ln -s usr/bin "${ROOTFS_BUILD}/bin"
ln -s usr/lib "${ROOTFS_BUILD}/lib"
ln -s usr/sbin "${ROOTFS_BUILD}/sbin"

mkdir -p "${ROOTFS_BUILD}/lib64"

cp -L \
    "${SYSROOT}/usr/lib/ld-linux-x86-64.so.2" \
    "${ROOTFS_BUILD}/lib64/ld-linux-x86-64.so.2"

chmod 0755 \
    "${ROOTFS_BUILD}/lib64/ld-linux-x86-64.so.2"

ln -sfn \
    ld-linux-x86-64.so.2 \
    "${ROOTFS_BUILD}/lib64/ld-lsb-x86-64.so.3"

mkdir -p \
    "${ROOTFS_BUILD}/dev" \
    "${ROOTFS_BUILD}/dev/pts" \
    "${ROOTFS_BUILD}/dev/shm" \
    "${ROOTFS_BUILD}/proc" \
    "${ROOTFS_BUILD}/sys" \
    "${ROOTFS_BUILD}/run" \
    "${ROOTFS_BUILD}/tmp" \
    "${ROOTFS_BUILD}/root" \
    "${ROOTFS_BUILD}/etc" \
    "${ROOTFS_BUILD}/usr/libexec" \
    "${ROOTFS_BUILD}/usr/lib/veyr-tests" \
    "${ROOTFS_BUILD}/usr/sbin"

chmod 1777 "${ROOTFS_BUILD}/tmp"

cp \
    "${BUSYBOX_BIN}" \
    "${ROOTFS_BUILD}/usr/libexec/busybox"

chmod 0755 \
    "${ROOTFS_BUILD}/usr/libexec/busybox"

cp \
    "${ROOT_INIT}" \
    "${ROOTFS_BUILD}/usr/libexec/veyr-alpha3-init"

chmod 0755 \
    "${ROOTFS_BUILD}/usr/libexec/veyr-alpha3-init"

ln -sfn \
    ../libexec/veyr-alpha3-init \
    "${ROOTFS_BUILD}/usr/sbin/init"

ln -sfn \
    ../libexec/busybox \
    "${ROOTFS_BUILD}/usr/sbin/poweroff"

ln -sfn \
    ../libexec/busybox \
    "${ROOTFS_BUILD}/usr/sbin/reboot"

cp \
    "${SMOKE_TEST}" \
    "${ROOTFS_BUILD}/usr/lib/veyr-tests/rootfs-alpha3-smoke.sh"

chmod 0755 \
    "${ROOTFS_BUILD}/usr/lib/veyr-tests/rootfs-alpha3-smoke.sh"

cp \
    "${ROOT_DIR}/rootfs/common/etc/motd" \
    "${ROOTFS_BUILD}/etc/motd"

sed \
    "s/@VERSION@/${VEYR_VERSION}/g" \
    "${ROOT_DIR}/rootfs/common/etc/os-release.in" \
    > "${ROOTFS_BUILD}/etc/os-release"

printf '%s\n' "${PROFILE}" \
    > "${ROOTFS_BUILD}/etc/veyr-image-profile"

printf '%s\n' 'veyr' \
    > "${ROOTFS_BUILD}/etc/hostname"

cat > "${ROOTFS_BUILD}/etc/passwd" <<'EOF'
root:x:0:0:root:/root:/usr/bin/bash
EOF

cat > "${ROOTFS_BUILD}/etc/group" <<'EOF'
root:x:0:
EOF

cat > "${ROOTFS_BUILD}/etc/nsswitch.conf" <<'EOF'
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
EOF

cat > "${ROOTFS_BUILD}/etc/hosts" <<'EOF'
127.0.0.1 localhost
127.0.1.1 veyr
::1       localhost
EOF

cat > "${ROOTFS_BUILD}/etc/fstab" <<'EOF'
/dev/vda  /      ext4     defaults  0  1
proc      /proc  proc     nosuid,noexec,nodev  0  0
sysfs     /sys   sysfs    nosuid,noexec,nodev  0  0
devtmpfs  /dev   devtmpfs mode=0755,nosuid  0  0
tmpfs     /run   tmpfs    mode=0755,nosuid,nodev  0  0
tmpfs     /tmp   tmpfs    mode=1777,nosuid,nodev  0  0
EOF

ln -sfn \
    /proc/self/mounts \
    "${ROOTFS_BUILD}/etc/mtab"

mkdir -p \
    "${ROOTFS_BUILD}/etc/ld.so.conf.d"

cat > "${ROOTFS_BUILD}/etc/ld.so.conf" <<'EOF'
/usr/lib
include /etc/ld.so.conf.d/*.conf
EOF

TARGET_LDCONFIG="${ROOTFS_BUILD}/usr/sbin/ldconfig"

LDCONFIG_INFO="$(file "${TARGET_LDCONFIG}")"

if ! grep -Eqi 'static|statically linked' <<<"${LDCONFIG_INFO}"; then
    die "Veyr ldconfig must be static for alpha.3 rootfs generation"
fi

"${TARGET_LDCONFIG}" \
    -r "${ROOTFS_BUILD}"

[[ -s "${ROOTFS_BUILD}/etc/ld.so.cache" ]] \
    || die "Failed to create alpha.3 /etc/ld.so.cache"

rm -rf \
    "${ROOTFS_BUILD}/usr/share/doc" \
    "${ROOTFS_BUILD}/usr/share/info" \
    "${ROOTFS_BUILD}/usr/share/man" \
    "${ROOTFS_BUILD}/usr/share/locale"

"${SCRIPT_DIR}/validate-alpha3-rootfs.sh" \
    "${ROOTFS_BUILD}"

log "Creating sparse ${ROOTFS_SIZE_MB} MiB ext4 root image"

rm -f "${ROOTFS_IMAGE}"

truncate \
    -s "${ROOTFS_SIZE_MB}M" \
    "${ROOTFS_IMAGE}"

mkfs.ext4 \
    -F \
    -q \
    -L VEYR_ROOT \
    -m 0 \
    -d "${ROOTFS_BUILD}" \
    "${ROOTFS_IMAGE}"

log "Checking ext4 filesystem"

e2fsck \
    -fn \
    "${ROOTFS_IMAGE}"

[[ -s "${ROOTFS_IMAGE}" ]] \
    || die "Alpha.3 root filesystem image was not created"

success "Alpha.3 root image created: ${ROOTFS_IMAGE}"

printf 'Logical size: '

du \
    -h \
    --apparent-size \
    "${ROOTFS_IMAGE}" \
    | awk '{print $1}'

printf 'Disk usage:   '

du \
    -h \
    "${ROOTFS_IMAGE}" \
    | awk '{print $1}'