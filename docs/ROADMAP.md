# Veyr Roadmap

Veyr is an independent Linux distribution built from upstream components.

Both future editions share one common **Veyr Base**:

- **Veyr Desktop** — for everyday users.
- **Veyr Developer** — for development workflows.

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
- `package.toml` manifests.
- `profile.toml` manifests.
- Dependency ordering.
- Source download and SHA-256 verification.
- Build output validation.
- Build fingerprints/cache.
- Image orchestration.
- Source mirror fallback.

# 0.1 — Veyr Base

Status: **in development**

## 0.1.0-alpha.1 — Cross Toolchain

Status: **done**

- Cross Binutils.
- GCC pass 1.
- Linux API headers.
- Bootstrap Glibc.
- `x86_64-veyr-linux-gnu` target.
- Cross-toolchain runtime verification.

## 0.1.0-alpha.2 — Temporary Userspace

Status: **done**

- Libstdc++ pass 1.
- M4.
- Ncurses.
- Bash.
- Coreutils.
- Diffutils.
- File.
- Findutils.
- Gawk.
- Grep.
- Gzip.
- Make.
- Patch.
- Sed.
- Tar.
- Xz.
- Binutils pass 2.
- GCC pass 2.
- Dynamic loader cache.
- C/C++ compilation inside the Veyr VM.

Success condition achieved:

```text
Temporary userspace verification result: PASS
Alpha.2 runtime verification: PASS
```

The alpha.2 experiment also demonstrated that storing the complete temporary
userspace in initramfs is not a viable architecture: reliable boot required
roughly 8 GiB of guest RAM.

## 0.1.0-alpha.3 — Disk Root & Chroot Foundation

Status: **current**

- Small static BusyBox early initramfs.
- Built-in kernel support for ext4 and virtio block devices.
- Sparse ext4 Veyr root filesystem image.
- QEMU root disk attached as `/dev/vda`.
- Early mount of `/dev/vda`.
- `switch_root` from initramfs into the Veyr disk root.
- Runtime verification that `/` is a writable ext4 disk root.
- C/C++ compiler verification from the disk-backed userspace.
- Controlled host-side chroot helper.
- Keep alpha.1/alpha.2 as regression profiles.

Success condition:

```text
Disk root verification result: PASS
Alpha.3 runtime verification: PASS
```

Target VM memory: approximately 2 GiB instead of alpha.2's 8 GiB.

## 0.1.0-alpha.4 — Additional temporary tools in chroot

Planned:

- Build from inside the Veyr filesystem rather than the Fedora userspace.
- Essential directory/file cleanup for the native build stage.
- Gettext.
- Bison.
- Perl.
- Zlib.
- mpdecimal.
- Python.
- Texinfo.
- Util-linux.
- Save/clean the temporary system.

This stage follows the same architectural boundary used by Linux From Scratch:
after the cross-built temporary toolchain, additional temporary tools are built
inside chroot.

## 0.1.0-alpha.5 — Final base userspace

Planned:

- Final Glibc.
- Final Binutils.
- Final GCC.
- Final Bash/Coreutils and essential packages.
- Kmod.
- E2fsprogs.
- Procps.
- D-Bus.
- Systemd.
- Essential `/etc` configuration.

Goal:

```text
kernel
  ↓
systemd
  ↓
login
  ↓
bash
```

without BusyBox as the primary userspace.

## 0.1.0 — Veyr Base

Release criteria:

- Real Glibc userspace.
- Bash/Coreutils environment.
- Systemd as init/system manager.
- Reproducible Veyr Base build.
- Disk-backed root filesystem.
- QEMU boot without BusyBox as the primary shell/userspace.

## 0.2 — Package artifacts and repository groundwork

- Binary package strategy.
- Package metadata.
- Repository generation.
- Signing groundwork.
- Update architecture groundwork.

## 0.3 — Persistent installation

- GPT/UEFI installation layout.
- Installer target disk handling.
- Bootloader installation.
- Boot installed Veyr without the development ISO.

## 0.4 — Hardware and network base

- Firmware.
- Networking.
- NetworkManager.
- Bluetooth.
- PipeWire/WirePlumber.
- Mesa/Wayland.

## 0.5 — Veyr Desktop

- KDE Plasma.
- Familiar Windows-style interaction model with original Veyr visuals.
- Graphical settings.
- Graphical software installation.
- Flatpak integration.
- Graphical updates.

## 0.6+ — Installer, updates and hardening

- Live image.
- Graphical installer.
- Btrfs snapshots/rollback.
- Signed update flow.
- Hardware compatibility.

## 1.0 — Veyr Desktop stable

Goal: an installable, updateable desktop for non-technical users where normal
tasks do not require the terminal.

## 1.x — Veyr Developer

Built on the same Veyr Base with development tooling and developer-oriented
defaults.
