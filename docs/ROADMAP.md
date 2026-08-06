# Veyr Roadmap

Veyr is an independent Linux distribution built from upstream components.

Both future editions share one common **Veyr Base**:

- **Veyr Desktop** — for everyday users.
- **Veyr Developer** — for development workflows.

---

## 0.0.1 — Bootstrap proof of concept

Status: **done**

- Bootable ISO.
- Upstream Linux kernel.
- Static BusyBox initramfs.
- GRUB boot menu.
- QEMU/KVM workflow.

---

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

---

# 0.1 — Veyr Base

Status: **in development**

The `0.1` milestone is split into internal alpha stages.

## 0.1.0-alpha.1 — Cross Toolchain

Status: **done**

- Binutils cross tools.
- GCC pass 1.
- GMP / MPFR / MPC sources for GCC.
- Linux API headers.
- Bootstrap Glibc.
- Veyr target triplet: `x86_64-veyr-linux-gnu`.
- Linker/sysroot runtime validation in QEMU.

## 0.1.0-alpha.2 — Temporary Userspace

Status: **current**

Planned/implemented package set:

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

Additional goals:

- Forge source mirror fallback.
- Dependency-aware build fingerprints.
- Preserve `bootstrap` and `base-alpha1` regression images.
- Boot the VM into real Bash.
- Compile and execute C and C++ programs inside Veyr itself.

Success condition:

```text
Temporary userspace verification result: PASS
Alpha.2 runtime verification: PASS
```

## 0.1.0-alpha.3 — Chroot and additional temporary tools

Planned:

- Controlled chroot entry.
- Essential users/groups and directory structure.
- Gettext.
- Bison.
- Perl.
- Zlib.
- Python.
- Texinfo.
- Util-linux.
- Save/clean temporary system.

Goal: build inside the Veyr filesystem rather than relying on Fedora userspace tools for the next stage.

## 0.1.0-alpha.4 — Final base userspace

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
- QEMU boot without BusyBox as the primary shell/userspace.

---

## 0.2 — Package artifacts and repository groundwork

- Binary package strategy.
- Package metadata.
- Repository generation.
- Signing groundwork.
- Update architecture groundwork.

---

## 0.3 — Persistent installation

- Virtual disk installation.
- GPT/UEFI layout.
- Persistent filesystem.
- Bootloader installation.
- Boot installed Veyr without ISO.

---

## 0.4 — Hardware and network base

- Firmware.
- Networking.
- NetworkManager.
- Bluetooth.
- PipeWire/WirePlumber.
- Mesa/Wayland.

---

## 0.5 — Veyr Desktop

- KDE Plasma.
- Familiar Windows-style interaction model with original Veyr visuals.
- Graphical settings.
- Graphical software installation.
- Flatpak integration.
- Graphical updates.

---

## 0.6+ — Installer, updates and hardening

- Live image.
- Graphical installer.
- Btrfs snapshots/rollback.
- Signed update flow.
- Hardware compatibility.

---

## 1.0 — Veyr Desktop stable

Goal: an installable, updateable desktop for non-technical users where normal tasks do not require the terminal.

---

## 1.x — Veyr Developer

Built on the same Veyr Base with development tooling and developer-oriented defaults.
