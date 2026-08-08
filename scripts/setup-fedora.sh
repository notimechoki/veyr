#!/usr/bin/env bash

set -Eeuo pipefail

echo "Installing Veyr build, Forge and image dependencies..."

sudo dnf install -y \
    python3 \
    gcc \
    gcc-c++ \
    make \
    bc \
    bison \
    flex \
    gawk \
    m4 \
    perl \
    patch \
    sed \
    diffutils \
    findutils \
    gettext \
    texinfo \
    which \
    git \
    curl \
    wget \
    rsync \
    cpio \
    gzip \
    bzip2 \
    xz \
    tar \
    file \
    e2fsprogs \
    openssl-devel \
    elfutils-libelf-devel \
    ncurses-devel \
    glibc-static \
    grub2-tools \
    grub2-tools-extra \
    xorriso \
    qemu-system-x86 \
    qemu-ui-gtk

echo
echo "Veyr host dependencies installed."
echo "Run './veyr doctor' to verify the host."