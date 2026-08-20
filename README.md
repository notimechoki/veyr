<p align="center">
  <img src="assets/banner/veyr-banner.png" alt="Veyr banner" width="100%" />
</p>

<p align="center"><strong>An independent Linux distribution built from upstream components.</strong></p>

<p align="center">
  <em>Current development stage: Veyr Base 0.1.0-alpha.4 — Native Chroot Tooling</em>
</p>

---

## About

**Veyr** is an independent Linux distribution project built from upstream
components instead of using Fedora, Ubuntu, Arch, or another distribution as
its runtime base.

The long-term architecture consists of one shared **Veyr Base** and two
editions:

- **Veyr Desktop** — a polished graphical edition for everyday users.
- **Veyr Developer** — a development-focused edition built on the same base.

Fedora is currently used only as the build host.

## Milestones

- **0.0.1** — bootable Linux + static BusyBox bootstrap image.
- **0.0.2** — Veyr Forge prototype.
- **0.1.0-alpha.1** — Veyr cross-toolchain + bootstrap Glibc.
- **0.1.0-alpha.2** — temporary GNU userspace + pass-2 compiler toolchain.
- **0.1.0-alpha.3** — small initramfs + ext4 disk root + `switch_root` + chroot foundation.
- **0.1.0-alpha.4** — Forge format 3 + native package builds inside the Veyr chroot.

Older profiles remain available as regression/development profiles.

## Alpha.4 architecture

```text
Fedora build host
      |
      v
Veyr Forge format 3
      |
      +--> alpha.1 cross toolchain
      +--> alpha.2 temporary userspace
      +--> alpha.3 disk-root foundation
      |
      v
prepare base-alpha4 rootfs
      |
      v
Veyr chroot
      |
      +--> Gettext
      +--> Bison
      +--> Perl
      +--> Zlib
      +--> mpdecimal
      +--> Python
      +--> Texinfo
      +--> Util-linux
      |
      v
ext4 Veyr root image
      |
      v
small BusyBox initramfs -> switch_root -> Veyr
```

Target triplet:

```text
x86_64-veyr-linux-gnu
```

## Requirements

The currently supported build host is Fedora Linux on x86_64.

```bash
make deps
./veyr doctor
```

## Build alpha.4

```bash
./veyr graph base-alpha4
./veyr fetch --profile base-alpha4
./veyr image base-alpha4
```

Or:

```bash
make alpha4
```

Artifacts:

```text
out/images/base-alpha4/initramfs.img
out/images/base-alpha4/veyr-rootfs.ext4
out/images/base-alpha4/Veyr-0.1.0-alpha.4-base-alpha4-x86_64.iso
```

## Run alpha.4

Serial/debug mode is recommended for the first run:

```bash
make run-alpha4-serial
```

Graphical:

```bash
./veyr run base-alpha4
```

A successful runtime prints:

```text
Native chroot tool verification: PASS
Alpha.4 runtime verification: PASS
```

## Native chroot stage only

To prepare the alpha.4 root and build only the native temporary tools:

```bash
./veyr build --profile temporary-alpha4
```

Then enter it interactively:

```bash
./scripts/chroot-alpha4.sh
```

## Regression profiles

```bash
make bootstrap
make alpha1
make alpha2
make alpha3
```

## Documentation

- [`docs/ROADMAP.md`](docs/ROADMAP.md)

## License

Veyr project tooling, scripts, manifests, documentation, and original project
assets are published under the repository license unless noted otherwise.
Upstream projects retain their own licenses.
