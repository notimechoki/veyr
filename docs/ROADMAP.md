# Veyr Roadmap

Veyr is an independent Linux distribution project built from upstream components.
The long-term architecture is based on a shared **Veyr Base** with two editions on top of it:

- **Veyr Desktop** — for everyday users.
- **Veyr Developer** — for programmers and development workflows.

---

## 0.0.1 — Bootstrap proof of concept

Status: **done**

### Goals

- Build a bootable ISO.
- Build the Linux kernel from upstream sources.
- Use a static BusyBox bootstrap userspace.
- Boot successfully in QEMU/KVM.
- Establish the initial repository structure.

### Result

Veyr can boot into a minimal bootstrap shell and prove the first independent build pipeline works.

---

## 0.0.2 — Forge prototype

Status: **done / active transition point**

### Goals

- Introduce **Veyr Forge**.
- Move from hardcoded build scripts to declarative manifests.
- Add package manifests via `package.toml`.
- Add profile manifests via `profile.toml`.
- Add package dependency graph resolution.
- Add SHA-256 source verification.
- Add build output validation.
- Add simple build cache / fingerprints.
- Rebuild the bootstrap image through Forge.

### Result

The bootstrap image is no longer just a set of standalone scripts — it is now orchestrated by Veyr Forge.
This creates the foundation needed for the real base-system work.

---

## 0.1 — Veyr Base

Status: **next major milestone**

### Goal

Replace the temporary BusyBox-only userspace with a real self-hosting base system.

### Planned work

#### Bootstrap toolchain

- Binutils pass 1
- GCC pass 1
- Linux API headers
- Glibc
- Temporary toolchain
- Final toolchain validation

#### Core userspace

- Bash
- Coreutils
- Diffutils
- Findutils
- Gawk
- Grep
- Gzip
- Make
- Patch
- Sed
- Tar
- Xz

#### Base system utilities

- Util-linux
- Kmod
- E2fsprogs
- OpenSSL
- Curl
- Procps or equivalent tools where needed

#### Init / system management

- Systemd
- D-Bus

### Deliverable

A first real **Veyr Base** able to move beyond a temporary BusyBox-only bootstrap environment.

---

## 0.2 — Package artifacts and repository groundwork

### Planned work

- Decide final package artifact strategy.
- Generate structured package outputs.
- Add local repository metadata generation.
- Add package signing groundwork.
- Prepare the basis for system updates.

### Deliverable

A more realistic internal package distribution model for Veyr.

---

## 0.3 — Persistent installation

### Planned work

- Support installation to a virtual disk.
- Partitioning and filesystem layout.
- Persistent root filesystem.
- Bootloader installation to installed system.
- Booting the installed system after reboot.

### Deliverable

Veyr no longer lives only inside a transient bootstrap image.

---

## 0.4 — Networking and hardware base

### Planned work

- Firmware handling
- Network stack setup
- NetworkManager
- Bluetooth base
- Audio stack groundwork
- Graphics stack groundwork

### Deliverable

A usable non-graphical system with a more realistic hardware base.

---

## 0.5 — Veyr Desktop foundation

### Planned work

- KDE Plasma integration
- SDDM or equivalent display manager
- Dolphin, Konsole, Discover
- Flatpak / Flathub integration
- First desktop-level branding
- User-friendly defaults

### Desktop design goal

The experience should be easy for people coming from Windows:

- familiar taskbar workflow,
- clean visuals,
- minimal need for terminal usage,
- graphical software installation,
- graphical updates.

### Deliverable

The first recognizable **Veyr Desktop** image.

---

## 0.6 — GUI software and update experience

### Planned work

- Brand the software center experience
- Improve graphical update flow
- Prepare rollback-friendly update design
- Improve out-of-box usability

### Deliverable

A more consumer-friendly daily-driver direction.

---

## 0.7 — Installer and live image

### Planned work

- Live boot mode
- Graphical installer
- Language, keyboard and disk selection
- User creation
- First-install experience

### Deliverable

A real installable desktop distro workflow.

---

## 1.0 — Veyr Desktop stable

### Goal

The first public stable milestone focused on non-technical users.

### Requirements

- installable,
- bootable,
- updateable,
- reasonably stable in virtual machines,
- easy to understand,
- no mandatory terminal usage for normal desktop tasks.

---

## 1.x — Veyr Developer

### Goal

Build a development-focused edition on top of the shared **Veyr Base**.

### Planned direction

- shared Veyr Base with Desktop,
- development packages and tooling,
- optional Hyprland or advanced desktop workflow,
- Git / Python / Node / Go / Rust / Docker / Podman,
- development-oriented defaults and shortcuts.

---

## Guiding principles

### 1. Independent distribution

Veyr should be built from upstream components rather than themed from an existing parent distro.

### 2. Shared base

Desktop and Developer editions must share the same core system.

### 3. Good UX

Veyr Desktop should be comfortable even for users moving from Windows.

### 4. Minimal unnecessary complexity

The project should avoid reinventing everything at once.
Use upstream components wisely and build the distro architecture step by step.

### 5. Reproducibility

Builds should become more structured, predictable and reproducible over time.
