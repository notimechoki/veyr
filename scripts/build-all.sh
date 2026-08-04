#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/fetch-sources.sh"

"${SCRIPT_DIR}/build-busybox.sh"

"${SCRIPT_DIR}/build-kernel.sh"

"${SCRIPT_DIR}/build-initramfs.sh"

"${SCRIPT_DIR}/build-iso.sh"

echo
echo "=========================================="
echo " Veyr build completed successfully"
echo "=========================================="