#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

ISO_FILE="${OUT_DIR}/images/bootstrap/Veyr-${VEYR_VERSION}-bootstrap-x86_64.iso"

[[ -f "${ISO_FILE}" ]] \
    || die "Veyr ISO not found. Run: ./veyr image bootstrap"

QEMU_ARGS=(
    -name "Veyr ${VEYR_VERSION} Bootstrap"
    -m 2048
    -smp 2
    -cdrom "${ISO_FILE}"
    -boot d
    -display gtk
)

if [[ -r /dev/kvm && -w /dev/kvm ]]; then

    log "KVM acceleration enabled"

    QEMU_ARGS+=(
        -enable-kvm
        -cpu host
    )

else

    warning "/dev/kvm unavailable. Using software emulation."

    QEMU_ARGS+=(
        -accel tcg
        -cpu max
    )

fi

log "Starting Veyr ${VEYR_VERSION}"

exec qemu-system-x86_64 "${QEMU_ARGS[@]}"