#!/usr/bin/bash

set -Eeuo pipefail

export PATH=/usr/bin:/usr/sbin:/bin:/sbin

unset LD_LIBRARY_PATH

echo "Veyr temporary userspace test"
echo "============================="

echo

if [[ -s /etc/ld.so.cache ]]; then
    echo "OK: /etc/ld.so.cache"
else
    echo "FAIL: /etc/ld.so.cache is missing or empty" >&2

    exit 1
fi

required_commands=(
    /usr/bin/bash
    /usr/bin/m4
    /usr/bin/tic
    /usr/bin/ls
    /usr/bin/uname
    /usr/bin/cat
    /usr/bin/head
    /usr/bin/sort
    /usr/bin/uniq
    /usr/bin/rm
    /usr/bin/mkdir
    /usr/bin/diff
    /usr/bin/file
    /usr/bin/find
    /usr/bin/gawk
    /usr/bin/grep
    /usr/bin/gzip
    /usr/bin/make
    /usr/bin/patch
    /usr/bin/sed
    /usr/bin/tar
    /usr/bin/xz
    /usr/bin/ld
    /usr/bin/readelf
    /usr/bin/gcc
    /usr/bin/g++
    /usr/bin/cc
)

for command_path in "${required_commands[@]}"; do
    if [[ ! -x "${command_path}" ]]; then
        echo "FAIL: missing ${command_path}" >&2

        exit 1
    fi

    echo "OK: ${command_path}"
done

echo
echo "Checking runtime libraries..."

required_libraries=(
    /usr/lib/libc.so.6
    /usr/lib/libm.so.6
    /usr/lib/libncursesw.so.6
    /usr/lib/libstdc++.so.6
    /usr/lib/libgcc_s.so.1
)

for library_path in "${required_libraries[@]}"; do
    if [[ ! -e "${library_path}" ]]; then
        echo "FAIL: missing ${library_path}" >&2

        exit 1
    fi

    echo "OK: ${library_path}"
done

echo
echo "Runtime identity:"

/usr/bin/bash --version \
    | /usr/bin/head -n 1

/usr/bin/ls --version \
    | /usr/bin/head -n 1

/usr/bin/uname -a

/usr/bin/gcc --version \
    | /usr/bin/head -n 1

/usr/bin/g++ --version \
    | /usr/bin/head -n 1

/usr/bin/ld --version \
    | /usr/bin/head -n 1

/usr/bin/make --version \
    | /usr/bin/head -n 1

TEST_DIR="/tmp/veyr-userspace-test"

rm -rf "${TEST_DIR}"

mkdir -p "${TEST_DIR}"

cat > "${TEST_DIR}/hello.c" <<'EOF_C'
#include <stdio.h>
#include <math.h>

int main(void)
{
    const double value = sqrt(144.0);

    printf("Veyr temporary C compiler test: OK\n");
    printf("sqrt(144) = %.0f\n", value);

    return 0;
}
EOF_C

echo
echo "Building C program inside Veyr..."

cc \
    -O2 \
    -Wall \
    -Wextra \
    "${TEST_DIR}/hello.c" \
    -lm \
    -o "${TEST_DIR}/hello-c"

"${TEST_DIR}/hello-c"

echo
echo "C executable interpreter:"

readelf \
    -l "${TEST_DIR}/hello-c" \
    | grep 'Requesting program interpreter'

cat > "${TEST_DIR}/hello.cpp" <<'EOF_CPP'
#include <iostream>
#include <string>
#include <cmath>

int main()
{
    const std::string name{"Veyr"};
    const double value = std::sqrt(225.0);

    std::cout
        << name
        << " temporary C++ compiler test: OK\n";

    std::cout
        << "sqrt(225) = "
        << value
        << '\n';

    return 0;
}
EOF_CPP

echo
echo "Building C++ program inside Veyr..."

g++ \
    -O2 \
    -Wall \
    -Wextra \
    "${TEST_DIR}/hello.cpp" \
    -o "${TEST_DIR}/hello-cpp"

"${TEST_DIR}/hello-cpp"

echo
echo "Inspecting produced C++ binary..."

file "${TEST_DIR}/hello-cpp"

readelf \
    -l "${TEST_DIR}/hello-cpp" \
    | grep 'Requesting program interpreter'

echo
echo "Testing Coreutils/Grep/Sed pipeline..."

printf 'alpha\nbeta\nbeta\n' \
    | grep beta \
    | sort \
    | uniq -c

printf 'Veyr\n' \
    | sed 's/Veyr/Veyr alpha.2/'

echo
echo "Testing archive/compression utilities..."

printf 'veyr-alpha2\n' \
    > "${TEST_DIR}/payload.txt"

tar \
    -cf "${TEST_DIR}/payload.tar" \
    -C "${TEST_DIR}" \
    payload.txt

gzip \
    -c "${TEST_DIR}/payload.txt" \
    > "${TEST_DIR}/payload.txt.gz"

xz \
    -c "${TEST_DIR}/payload.txt" \
    > "${TEST_DIR}/payload.txt.xz"

[[ -s "${TEST_DIR}/payload.tar" ]]
[[ -s "${TEST_DIR}/payload.txt.gz" ]]
[[ -s "${TEST_DIR}/payload.txt.xz" ]]

echo
echo "Temporary userspace verification result: PASS"