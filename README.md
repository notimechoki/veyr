<p align="center">
  <img src="assets/banner/veyr-banner.png" alt="Veyr banner" width="100%" />
</p>

<p align="center"><strong>An independent Linux distribution built from upstream components.</strong></p>

<p align="center">
  <em>Current development stage: Veyr Base 0.1.0-alpha.2 — Temporary Userspace</em>
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
- **0.0.2** — Veyr Forge prototype.
- **0.1.0-alpha.1** — cross Binutils/GCC + Linux API headers + bootstrap Glibc.
- **0.1.0-alpha.2** — temporary Veyr userspace + pass-2 compiler toolchain.

The original `bootstrap` and `base-alpha1` profiles remain available as regression/control images.

---

## Alpha.2 architecture

```text
Fedora build host
      |
      v
Veyr Forge
      |
      +--> alpha.1 cross toolchain
      |
      +--> Libstdc++ pass 1
      +--> M4
      +--> Ncurses
      +--> Bash
      +--> Coreutils
      +--> Diffutils / File / Findutils
      +--> Gawk / Grep / Gzip
      +--> Make / Patch / Sed / Tar / Xz
      +--> Binutils pass 2
      +--> GCC pass 2
      |
      v
out/sysroot/usr
      |
      v
base-alpha2 initramfs
      |
      +--> static BusyBox only for early init helpers
      |
      v
Bash userspace + GCC runtime test
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

The currently supported build host is Fedora Linux on x86_64.

Install dependencies:

```bash
make deps
```

Verify the host:

```bash
./veyr doctor
```

---

## Build alpha.2

Inspect the graph:

```bash
./veyr graph base-alpha2
```

Fetch sources:

```bash
./veyr fetch --profile base-alpha2
```

Build the temporary userspace only:

```bash
make temporary
```

Build the complete alpha.2 image:

```bash
make alpha2
```

or:

```bash
./veyr image base-alpha2
```

---

## Run in QEMU/KVM

```bash
make run
```

or:

```bash
./veyr run base-alpha2
```

A successful boot should contain:

```text
Veyr temporary C compiler test: OK
Veyr temporary C++ compiler test: OK
Temporary userspace verification result: PASS
Alpha.2 runtime verification: PASS
```

The interactive shell is now `/usr/bin/bash`.

BusyBox is retained only as a static early-boot helper for operations such as mounting `/proc`, `/sys`, and setting up the controlling terminal.

---

## Regression profiles

Original bootstrap:

```bash
make bootstrap
make bootstrap-run
```

Alpha.1:

```bash
make alpha1
make run-alpha1
```

---

## Important paths

Cross-toolchain:

```text
out/sysroot/tools/
```

Temporary target userspace:

```text
out/sysroot/usr/
```

Alpha.2 image:

```text
out/images/base-alpha2/
```

Runtime smoke test:

```text
tests/userspace/smoke.sh
```

---

## Useful Forge commands

```bash
./veyr --version
./veyr doctor
./veyr list packages
./veyr list profiles
./veyr graph base-alpha2
./veyr info profile base-alpha2
./veyr fetch --profile base-alpha2
./veyr build --profile temporary-alpha2
./veyr image base-alpha2
./veyr run base-alpha2
./veyr clean
```

---

## Forge source mirrors

Forge format 2 supports multiple source URLs in a package manifest:

```toml
[source]
urls = [
  "https://primary.example/package.tar.xz",
  "https://mirror.example/package.tar.xz",
]
archive = "package.tar.xz"
sha256 = "..."
```

If one endpoint returns an HTTP error, Forge tries the next source. A file is accepted only if its SHA-256 matches the pinned value.

---

## Roadmap

See [`docs/ROADMAP.md`](docs/ROADMAP.md).

---

## License

Veyr project tooling, scripts, manifests, documentation, and original project assets are published under the repository license unless noted otherwise.

Upstream projects retain their own licenses.
