<p align="center">
  <img src="assets/banner/veyr-banner.png" alt="Veyr banner" width="100%" />
</p>

<p align="center"><strong>An independent Linux distribution built from upstream components.</strong></p>

<p align="center">
  <em>Current development stage: Veyr Base 0.1.0-alpha.1 — Cross Toolchain</em>
</p>

---

## About

**Veyr** is an independent Linux distribution project built from upstream components instead of using Fedora, Ubuntu, Arch, or another distribution as its runtime base.

The long-term architecture consists of one shared **Veyr Base** and two editions:

- **Veyr Desktop** — a polished, graphical edition for everyday users.
- **Veyr Developer** — a development-focused edition built on the same base.

Fedora is currently used only as the build host.

---

## Milestones

- **0.0.1** — bootable Linux + static BusyBox bootstrap image.
- **0.0.2** — Veyr Forge prototype with package/profile manifests and build orchestration.
- **0.1.0-alpha.1** — cross Binutils + cross GCC + Linux API headers + bootstrap Glibc validation.

The original `bootstrap` profile remains available as a known-good recovery/control image while Veyr Base is being developed.

---

## Current architecture

```text
Fedora build host
      |
      v
Veyr Forge
      |
      +--> Binutils cross
      +--> GCC pass 1
      +--> Linux API headers
      +--> Glibc bootstrap
      |
      v
out/sysroot
      |
      +--> toolchain sanity test
      |
      v
Veyr base-alpha1 initramfs
      |
      v
QEMU/KVM
```

Target triplet:

```text
x86_64-veyr-linux-gnu
```

---

## Requirements

The current supported build host is Fedora Linux on x86_64.

Install host dependencies:

```bash
make deps
```

Verify them:

```bash
./veyr doctor
```

---

## Build Veyr Base alpha.1

Inspect the dependency graph:

```bash
./veyr graph base-alpha1
```

Build the full image:

```bash
./veyr image base-alpha1
```

Or:

```bash
make alpha1
```

The build produces a Veyr sysroot under:

```text
out/sysroot/
```

and the alpha image under:

```text
out/images/base-alpha1/
```

---

## Run in QEMU/KVM

```bash
./veyr run base-alpha1
```

or:

```bash
make run
```

During boot, the initramfs automatically runs a dynamically linked program produced by the Veyr cross compiler. A successful result contains:

```text
Veyr cross-toolchain userspace test: OK
Runtime verification result: PASS
```

This verifies that a Veyr-built program can load using the bootstrap Veyr Glibc inside the VM.

---

## Keep testing the old bootstrap

The previous minimal image is intentionally preserved:

```bash
./veyr image bootstrap
./veyr run bootstrap
```

This is useful for catching regressions in the image pipeline independently of the new toolchain.

---

## Useful Forge commands

```bash
./veyr --version
./veyr list packages
./veyr list profiles
./veyr info profile base-alpha1
./veyr graph base-alpha1
./veyr fetch --profile base-alpha1
./veyr build binutils-cross
./veyr build gcc-cross
./veyr build linux-headers
./veyr build glibc-bootstrap
./veyr build --profile base-alpha1
./veyr image base-alpha1
./veyr run base-alpha1
./veyr clean
```

Force a rebuild when changing a lower-level toolchain dependency:

```bash
./veyr image base-alpha1 --rebuild
```

---

## Repository layout

```text
veyr/
├── assets/
├── config/
├── docs/
├── initramfs/
├── iso/
├── packages/
│   ├── core/
│   ├── toolchain/
│   ├── desktop/
│   └── developer/
├── profiles/
├── rootfs/
├── scripts/
├── tests/
├── tools/
│   └── forge/
├── build/
├── sources/
├── out/
└── veyr
```

---

## Roadmap

See [`docs/ROADMAP.md`](docs/ROADMAP.md).

---

## License

Veyr project tooling, scripts, manifests and documentation are published under the MIT License unless noted otherwise. Upstream components retain their own licenses.
