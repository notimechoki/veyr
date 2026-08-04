# Veyr Roadmap

Veyr is an independent Linux distribution project built from upstream components.
Desktop and Developer editions share the same Veyr Base.

## 0.0.1 - Bootstrap proof of concept

- Bootable ISO.
- Upstream Linux kernel.
- Static BusyBox initramfs.
- GRUB boot menu.
- QEMU/KVM development workflow.

## 0.0.2 - Forge prototype

- Declarative `package.toml` manifests.
- Declarative `profile.toml` manifests.
- Package dependency graph.
- Source downloading and SHA-256 verification.
- Generic source extraction.
- Package build orchestration.
- Build cache/fingerprints.
- Bootstrap image orchestration.
- Host environment diagnostics.

## 0.1 - Veyr Base

Replace the temporary BusyBox-only userspace with a real self-hosting base system.
Planned work includes the bootstrap toolchain and final userspace packages such as:

- Binutils.
- GCC.
- Linux API headers.
- Glibc.
- Bash.
- Coreutils.
- Findutils.
- Diffutils.
- Gawk.
- Grep.
- Gzip.
- Make.
- Patch.
- Sed.
- Tar.
- Xz.
- Util-linux.
- Kmod.
- E2fsprogs.
- OpenSSL.
- Systemd.
- D-Bus.

The exact build order will be encoded as Forge package dependencies rather than a hard-coded shell sequence.

## Later milestones

### 0.2 - Package artifacts and local repository

- Veyr binary package format or selected package backend.
- Package metadata database.
- Local repository generation.
- Signed package metadata.

### 0.3 - Persistent installation

- Virtual disk installation.
- Partitioning and filesystems.
- Bootloader installation.
- Persistent root filesystem.

### 0.4 - Networking and hardware base

- NetworkManager.
- Firmware.
- Bluetooth.
- Audio stack.
- Graphics stack.

### 0.5 - Veyr Desktop

- KDE Plasma.
- Windows-familiar desktop layout with Veyr branding.
- Graphical software installation.
- Graphical system updates.
- Flatpak integration.

### 1.0 - Veyr Desktop stable

A desktop release intended for non-technical users.

### 1.x - Veyr Developer

Developer-focused profile sharing Veyr Base with Veyr Desktop.