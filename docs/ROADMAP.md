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

The `0.1` milestone is intentionally split into internal alpha stages. The public `0.1.0` milestone is reached only after the real base userspace is complete and bootable.

## 0.1.0-alpha.1 — Cross Toolchain

Status: **current**

Goals:

- Binutils 2.47 cross tools.
- GCC 16.1.0 pass 1.
- GMP 6.3.0 sources for GCC.
- MPFR 4.2.2 sources for GCC.
- MPC 1.4.1 sources for GCC.
- Linux 7.1.5 API headers.
- Glibc 2.44 bootstrap installation.
- Veyr target triplet: `x86_64-veyr-linux-gnu`.
- Linker/sysroot sanity checks.
- Execute a dynamically linked Veyr test binary inside QEMU/KVM.

Deliverable:

```text
out/sysroot/tools/bin/x86_64-veyr-linux-gnu-gcc
out/sysroot/usr/include/
out/sysroot/usr/lib/libc.so.6
out/sysroot/usr/lib/ld-linux-x86-64.so.2
```

The image still uses static BusyBox as PID 1 / shell. Its purpose is to prove the new Veyr toolchain and Glibc work at runtime.

## 0.1.0-alpha.2 — Temporary userspace

Planned:

- Libstdc++ temporary build.
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

Goal: create enough Veyr-native temporary tooling to stop depending on the Fedora userspace during later system construction.

## 0.1.0-alpha.3 — Final base userspace

Planned:

- Controlled chroot build stage.
- Final Glibc.
- Final Binutils/GCC.
- Bash and Coreutils as real Veyr userspace.
- Util-linux.
- Kmod.
- E2fsprogs.
- Procps.
- D-Bus.
- Systemd.
- Essential `/etc` configuration.

Goal: boot a real Veyr Base userspace instead of the BusyBox bootstrap shell.

## 0.1.0 — Veyr Base

Planned release criteria:

- Real Glibc userspace.
- Bash/Coreutils environment.
- Systemd as init/system manager.
- Veyr can boot in QEMU without relying on BusyBox as the primary userspace.
- Build pipeline reproducibly reconstructs the base from pinned upstream sources.

---

## 0.2 — Package artifacts and repository groundwork

- Binary package strategy.
- Package metadata database.
- Repository generation.
- Signing groundwork.
- Update architecture groundwork.

---

## 0.3 — Persistent installation

- Virtual disk installation.
- GPT/UEFI layout.
- Persistent root filesystem.
- Bootloader installation.
- Boot installed Veyr after removing the ISO.

---

## 0.4 — Hardware/network base

- Firmware.
- Networking.
- NetworkManager.
- Bluetooth.
- PipeWire/WirePlumber.
- Mesa/Wayland graphics groundwork.

---

## 0.5 — Veyr Desktop

- KDE Plasma.
- Familiar Windows-style interaction model with original Veyr visuals.
- Graphical settings.
- Graphical application installation.
- Flatpak integration.
- Graphical updates.

---

## 0.6+ — Installer, updates and desktop hardening

- Live image.
- Graphical installer.
- Btrfs snapshot/rollback design.
- Signed update flow.
- Hardware compatibility work.

---

## 1.0 — Veyr Desktop stable

Goal: an installable, updateable daily desktop for non-technical users where normal tasks do not require the terminal.

---

## 1.x — Veyr Developer

Built on the same Veyr Base with development tooling, advanced workflow defaults, and an optional developer-oriented desktop environment.
