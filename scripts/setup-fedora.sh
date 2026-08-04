#!/usr/bin/env bash

set -Eeuo pipefail

echo "Installing Veyr build dependencies..."

sudo dnf install -y \
    gcc \
    gcc-c++ \
    make \
    bc \
    bison \
    flex \
    perl \
    patch \
    git \
    curl \
    wget \
    rsync \
    cpio \
    gzip \
    bzip2 \
    xz \
    tar \
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
echo "Veyr build dependencies installed."