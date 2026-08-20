# Veyr Roadmap

Veyr is an independent Linux distribution built from upstream components.
Both future editions share one common **Veyr Base**.

## 0.0.1 — Bootstrap proof of concept

Status: **done**

- Bootable ISO.
- Upstream Linux kernel.
- Static BusyBox initramfs.
- GRUB boot menu.
- QEMU/KVM workflow.

## 0.0.2 — Forge prototype

Status: **done**

- Veyr Forge CLI.
- Package/profile manifests.
- Dependency ordering.
- Verified source downloads.
- Build fingerprints/cache.
- Image orchestration.

# 0.1 — Veyr Base

Status: **in development**

## 0.1.0-alpha.1 — Cross Toolchain

Status: **done**

- Cross Binutils 2.47.
- GCC 16.1.0 pass 1.
- Linux 7.1.5 API headers.
- Glibc 2.44 bootstrap.
- `x86_64-veyr-linux-gnu` target.

## 0.1.0-alpha.2 — Temporary Userspace

Status: **done**

- Cross-built temporary GNU userspace.
- Binutils/GCC pass 2.
- C/C++ compilation in Veyr.
- Static rescue environment.

## 0.1.0-alpha.3 — Disk Root & Chroot Foundation

Status: **done**

- Small early initramfs.
- Ext4 disk-backed root.
- Virtio `/dev/vda`.
- `switch_root`.
- 2 GiB VM target.
- Controlled chroot helper.

## 0.1.0-alpha.4 — Native Chroot Tooling

Status: **current**

- Forge format 3.
- Host/chroot package build environments.
- Profile prepare stage.
- Native build provenance markers.
- Gettext 1.0.
- Bison 3.8.2.
- Perl 5.44.0.
- Zlib 1.3.2.
- mpdecimal 4.0.1.
- Python 3.14.7.
- Texinfo 7.3.
- Util-linux 2.42.2.
- Runtime tests for the native tool set.

Success condition:

```text
Native chroot tool verification: PASS
Alpha.4 runtime verification: PASS
```

## 0.1.0-alpha.5 — Final Base Userspace, part 1

Planned:

- Begin replacing temporary toolchain components with final builds.
- Final Glibc/Binutils/GCC transition.
- Base libraries and core utilities required by the final userspace.

## 0.1.0-alpha.6 — Final Base Userspace, part 2

Planned:

- Remaining essential packages.
- E2fsprogs, Procps-ng, Kmod and related system utilities.
- D-Bus/system integration groundwork.

## 0.1.0-alpha.7 — systemd boot

Planned goal:

```text
kernel
  ↓
systemd PID 1
  ↓
services
  ↓
login
  ↓
bash
```

## 0.1.0 — Veyr Base

Release criteria:

- Final Glibc userspace.
- Final compiler/base tools.
- systemd as init/system manager.
- Reproducible disk-backed Veyr Base image.
- QEMU boot without BusyBox as the primary userspace.

## 0.2 — Package artifacts and repository groundwork

- Binary package strategy.
- Package metadata.
- Repository generation.
- Signing and update groundwork.

## 0.3 — Persistent installation

- GPT/UEFI installation layout.
- Installer target disk handling.
- Bootloader installation.
- Boot installed Veyr without the development ISO.

## 0.4 — Hardware and network base

- Firmware.
- Networking and NetworkManager.
- Bluetooth.
- PipeWire/WirePlumber.
- Mesa/Wayland.

## 0.5 — Veyr Desktop

- KDE Plasma.
- Familiar Windows-style interaction model with original Veyr visuals.
- Graphical settings/software/update workflows.
- Flatpak integration.

## 1.0 — Veyr Desktop stable

Goal: an installable, updateable desktop for non-technical users where normal
tasks do not require the terminal.
