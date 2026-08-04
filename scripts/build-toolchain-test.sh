#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

export VEYR_ROOT="${ROOT_DIR}"

source "${ROOT_DIR}/scripts/lib/toolchain.sh"

require_cross_tool gcc
require_cross_tool readelf

TEST_BUILD="${ROOT_DIR}/build/tests/toolchain"
TEST_OUT="${ROOT_DIR}/out/tests/toolchain"

TEST_BINARY="${TEST_OUT}/veyr-toolchain-test"
LOG_FILE="${TEST_BUILD}/linker.log"
SANITY_BINARY="${TEST_BUILD}/sanity"

rm -rf "${TEST_BUILD}"

mkdir -p \
    "${TEST_BUILD}" \
    "${TEST_OUT}"

printf '\n[TOOLCHAIN-TEST] Running linker/sysroot sanity check\n'

printf 'int main(void){return 0;}\n' \
    | "${VEYR_TARGET}-gcc" \
        --sysroot="${VEYR_SYSROOT}" \
        -x c - \
        -v \
        -Wl,--verbose \
        -o "${SANITY_BINARY}" \
        > "${LOG_FILE}" 2>&1

INTERPRETER_LINE="$(
    "${VEYR_TARGET}-readelf" \
        -l \
        "${SANITY_BINARY}" \
        | grep 'Requesting program interpreter' \
        || true
)"

echo "${INTERPRETER_LINE}"

echo "${INTERPRETER_LINE}" \
    | grep -q '/lib64/ld-linux-x86-64.so.2' \
    || {
        echo "Unexpected dynamic loader in Veyr test binary." >&2
        exit 1
    }

if echo "${INTERPRETER_LINE}" | grep -q "${VEYR_SYSROOT}"; then

    echo "The runtime interpreter incorrectly contains the host sysroot path." >&2

    exit 1
fi

grep -q \
    "${VEYR_SYSROOT}/usr/include" \
    "${LOG_FILE}" \
    || {
        echo "Cross GCC did not search the Veyr sysroot headers." >&2
        exit 1
    }

grep -q \
    "${VEYR_SYSROOT}/usr/lib/libc.so.6" \
    "${LOG_FILE}" \
    || {
        echo "Cross linker did not use the Veyr sysroot libc." >&2
        exit 1
    }

printf '[TOOLCHAIN-TEST] Building VM smoke-test binary\n'

"${VEYR_TARGET}-gcc" \
    --sysroot="${VEYR_SYSROOT}" \
    -O2 \
    -Wall \
    -Wextra \
    "${ROOT_DIR}/tests/toolchain/hello.c" \
    -o "${TEST_BINARY}"

"${VEYR_TARGET}-readelf" \
    -d \
    "${TEST_BINARY}" \
    | grep -q 'Shared library: \[libc.so.6\]' \
    || {
        echo "VM smoke-test binary is not linked against libc.so.6." >&2
        exit 1
    }

"${VEYR_TARGET}-readelf" \
    -l \
    "${TEST_BINARY}" \
    | grep 'Requesting program interpreter'

printf '[TOOLCHAIN-TEST] Output: %s\n' \
    "${TEST_BINARY}"

printf '[TOOLCHAIN-TEST] Host-side toolchain checks passed\n'