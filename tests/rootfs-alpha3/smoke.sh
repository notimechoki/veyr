#!/usr/bin/bash

set -Eeuo pipefail

export PATH=/usr/bin:/usr/sbin:/bin:/sbin
unset LD_LIBRARY_PATH

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

echo "Veyr alpha.3 disk-root test"
echo "==========================="

if ! grep -Eq '^/dev/vda / ext4 ' /proc/mounts; then
    echo "Current root mounts:" >&2
    grep ' / ' /proc/mounts >&2 || true

    fail "root filesystem is not /dev/vda ext4"
fi

echo "OK: root filesystem is /dev/vda (ext4)"

if [[ -e /init ]]; then
    fail "old initramfs /init is still visible after switch_root"
fi

echo "OK: old initramfs root was discarded"

if [[ ! -s /etc/ld.so.cache ]]; then
    fail "/etc/ld.so.cache is missing"
fi

echo "OK: dynamic loader cache exists"

required_commands=(
    /usr/bin/bash
    /usr/bin/ls
    /usr/bin/cat
    /usr/bin/grep
    /usr/bin/df
    /usr/bin/file
    /usr/bin/make
    /usr/bin/gcc
    /usr/bin/g++
    /usr/bin/cc
)

for command_path in "${required_commands[@]}"; do
    [[ -x "$command_path" ]] || fail "missing ${command_path}"

    echo "OK: ${command_path}"
done

echo
echo "Root filesystem:"

df -h /

echo
echo "Runtime identity:"

bash --version | head -n 1
ls --version | head -n 1
uname -a
gcc --version | head -n 1
g++ --version | head -n 1
make --version | head -n 1

TEST_DIR=/tmp/veyr-alpha3-test

rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

echo "disk-write-ok" > "$TEST_DIR/persistent-root-check"

grep -qx 'disk-write-ok' "$TEST_DIR/persistent-root-check" \
    || fail "unable to write to disk-backed root filesystem"

echo "OK: disk-backed root is writable"

cat > "$TEST_DIR/hello.c" <<'EOF'
#include <stdio.h>

int main(void)
{
    puts("Veyr alpha.3 C compiler test: OK");
    return 0;
}
EOF

cc \
    -O2 \
    -Wall \
    -Wextra \
    "$TEST_DIR/hello.c" \
    -o "$TEST_DIR/hello-c"

"$TEST_DIR/hello-c"

cat > "$TEST_DIR/hello.cpp" <<'EOF'
#include <iostream>

int main()
{
    std::cout << "Veyr alpha.3 C++ compiler test: OK\n";
    return 0;
}
EOF

g++ \
    -O2 \
    -Wall \
    -Wextra \
    "$TEST_DIR/hello.cpp" \
    -o "$TEST_DIR/hello-cpp"

"$TEST_DIR/hello-cpp"

echo
echo "Disk root verification result: PASS"