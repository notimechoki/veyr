<p align="center">
  <img src="assets/banner/veyr-banner.png" alt="Veyr banner" width="100%" />
</p>

<p align="center"><strong>An independent Linux distribution built from upstream components.</strong></p>

<p align="center">
  <em>Current development stage: Veyr Base 0.1.0-alpha.3 — Disk Root & Chroot Foundation</em>
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
- **0.1.0-alpha.3** — small early initramfs + ext4 disk root + `switch_root` + controlled chroot workflow.

The older `bootstrap`, `base-alpha1`, and `base-alpha2` profiles remain in the
repository as regression/development profiles.

## Alpha.3 architecture

```text
Fedora build host
      |
      v
Veyr Forge
      |
      +--> alpha.1 cross toolchain
      |
      +--> alpha.2 temporary userspace
      |
      +--> small static BusyBox initramfs
      |
      +--> sparse ext4 Veyr root image
      |
      v
QEMU
      |
      v
Linux 7.1.5
      |
      v
/init in small initramfs
      |
      v
/dev/vda -> /newroot
      |
      v
switch_root
      |
      v
/sbin/init on Veyr ext4 root
      |
      v
Bash + GCC/G++ runtime verification
```

Target triplet:

```text
x86_64-veyr-linux-gnu
```

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

## Build alpha.3

Inspect the graph:

```bash
./veyr graph base-alpha3
```

Fetch sources:

```bash
./veyr fetch --profile base-alpha3
```

Build the image:

```bash
make alpha3
```

or:

```bash
./veyr image base-alpha3
```

Generated artifacts:

```text
out/images/base-alpha3/initramfs.img
out/images/base-alpha3/veyr-rootfs.ext4
out/images/base-alpha3/Veyr-0.1.0-alpha.3-base-alpha3-x86_64.iso
```

The root filesystem image is sparse and defaults to an 8 GiB logical size.
Unlike alpha.2, the complete userspace is no longer unpacked into guest RAM.

## Run in QEMU

Graphical:

```bash
make run
```

or:

```bash
./veyr run base-alpha3
```

Serial/debug mode:

```bash
make run-alpha3-serial
```

A successful boot should contain:

```text
Disk root verification result: PASS
Alpha.3 runtime verification: PASS
```

The normal alpha.3 VM uses approximately 2 GiB of guest RAM instead of the 8
GiB required by alpha.2's giant initramfs.

## Enter the Veyr chroot

After building alpha.3:

```bash
make chroot-alpha3
```

or:

```bash
./scripts/chroot-alpha3.sh
```

The helper prepares the virtual kernel filesystems, enters the staging Veyr
root with a clean environment, and unmounts everything on exit.

## Regression profiles

Bootstrap:

```bash
make bootstrap
make bootstrap-run
```

Alpha.1:

```bash
make alpha1
make run-alpha1
```

Alpha.2:

```bash
make alpha2
make run-alpha2
```

Alpha.2 intentionally retains its 8 GiB VM configuration because its userspace
is stored entirely in initramfs.

## Useful Forge commands

```bash
./veyr --version
./veyr doctor
./veyr list packages
./veyr list profiles
./veyr graph base-alpha3
./veyr info profile base-alpha3
./veyr fetch --profile base-alpha3
./veyr image base-alpha3
./veyr run base-alpha3
./veyr clean
```

## Roadmap

See [`docs/ROADMAP.md`](docs/ROADMAP.md).

## License

Veyr project tooling, scripts, manifests, documentation, and original project
assets are published under the repository license unless noted otherwise.

Upstream projects retain their own licenses.
