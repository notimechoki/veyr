#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

try:
    import tomllib
except ModuleNotFoundError as exc:
    raise SystemExit(
        "Veyr Forge requires Python 3.11 or newer (tomllib is missing)."
    ) from exc


ROOT = Path(__file__).resolve().parents[2]
CONFIG_FILE = ROOT / "config" / "forge.toml"
VERSION_FILE = ROOT / "VERSION"


class ForgeError(RuntimeError):
    pass


def blue(text: str) -> str:
    return f"\033[1;34m{text}\033[0m"


def green(text: str) -> str:
    return f"\033[1;32m{text}\033[0m"


def yellow(text: str) -> str:
    return f"\033[1;33m{text}\033[0m"


def red(text: str) -> str:
    return f"\033[1;31m{text}\033[0m"


def log(message: str) -> None:
    print(f"\n{blue('[FORGE]')} {message}")


def ok(message: str) -> None:
    print(f"{green('[OK]')} {message}")


def warn(message: str) -> None:
    print(f"{yellow('[WARN]')} {message}")


def fail(message: str) -> None:
    raise ForgeError(message)


def load_toml(path: Path) -> dict[str, Any]:
    if not path.is_file():
        fail(f"TOML file not found: {path.relative_to(ROOT)}")

    try:
        with path.open("rb") as handle:
            return tomllib.load(handle)
    except tomllib.TOMLDecodeError as exc:
        fail(f"Invalid TOML in {path.relative_to(ROOT)}: {exc}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()

    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)

    return digest.hexdigest()


def hash_bytes(*parts: bytes) -> str:
    digest = hashlib.sha256()

    for part in parts:
        digest.update(part)

    return digest.hexdigest()


def ensure_within_root(path: Path) -> Path:
    resolved = path.resolve()

    try:
        resolved.relative_to(ROOT.resolve())
    except ValueError:
        fail(f"Refusing to operate outside the Veyr repository: {resolved}")

    return resolved


def remove_tree_contents(path: Path) -> None:
    path = ensure_within_root(path)

    if path.exists():
        shutil.rmtree(path)

    path.mkdir(parents=True, exist_ok=True)


@dataclass(frozen=True)
class Package:
    name: str
    version: str
    category: str
    description: str

    dependencies: tuple[str, ...]
    required_commands: tuple[str, ...]
    outputs: tuple[Path, ...]

    source_urls: tuple[str, ...]
    source_archive: str
    source_sha256: str

    build_script: Path
    build_environment: str
    manifest: Path


@dataclass(frozen=True)
class Profile:
    id: str
    name: str
    status: str
    description: str

    parent: str
    packages: tuple[str, ...]

    prepare_steps: tuple[Path, ...]
    chroot_root: Path | None

    image_steps: tuple[Path, ...]
    run_script: Path | None

    manifest: Path


class Forge:
    def __init__(self) -> None:
        self.config = load_toml(CONFIG_FILE)
        self.version = VERSION_FILE.read_text(encoding="utf-8").strip()

        project = self.config.get("project", {})
        paths = self.config.get("paths", {})

        self.arch = str(project.get("architecture", "x86_64"))
        self.min_python = str(project.get("min_python", "3.11"))

        self.packages_dir = ROOT / str(paths.get("packages", "packages"))
        self.profiles_dir = ROOT / str(paths.get("profiles", "profiles"))
        self.sources_dir = ROOT / str(paths.get("sources", "sources/distfiles"))
        self.build_dir = ROOT / str(paths.get("build", "build"))
        self.out_dir = ROOT / str(paths.get("out", "out"))
        self.state_dir = self.build_dir / "state" / "packages"

        for directory in (
            self.packages_dir,
            self.profiles_dir,
            self.sources_dir,
            self.build_dir,
            self.out_dir,
            self.state_dir,
        ):
            directory.mkdir(parents=True, exist_ok=True)

        self.packages = self._load_packages()
        self.profiles = self._load_profiles()
        self._validate_references()

    def _load_packages(self) -> dict[str, Package]:
        packages: dict[str, Package] = {}

        for manifest in sorted(self.packages_dir.rglob("package.toml")):
            data = load_toml(manifest)
            package_data = data.get("package", {})
            source_data = data.get("source", {})
            build_data = data.get("build", {})

            name = str(package_data.get("name", "")).strip()
            if not name:
                fail(f"Package name is missing in {manifest.relative_to(ROOT)}")
            if name in packages:
                fail(f"Duplicate package name: {name}")

            script_name = str(build_data.get("script", "build.sh"))
            build_script = manifest.parent / script_name
            if not build_script.is_file():
                fail(
                    f"Build script not found for package {name}: "
                    f"{build_script.relative_to(ROOT)}"
                )

            build_environment = str(
                build_data.get("environment", "host")
            ).strip().lower()

            if build_environment not in {"host", "chroot"}:
                fail(
                    f"Package {name} has unsupported build environment: "
                    f"{build_environment}"
                )

            outputs = tuple(
                ROOT / str(item)
                for item in package_data.get("outputs", [])
            )

            packages[name] = Package(
                name=name,
                version=str(package_data.get("version", "")),
                category=str(package_data.get("category", "core")),
                description=str(package_data.get("description", "")),
                dependencies=tuple(
                    str(item) for item in package_data.get("dependencies", [])
                ),
                required_commands=tuple(
                    str(item)
                    for item in package_data.get("required_commands", [])
                ),
                outputs=outputs,
                source_urls=tuple(
                    str(item)
                    for item in (
                        source_data.get("urls")
                        or [source_data.get("url", "")]
                    )
                    if str(item).strip()
                ),
                source_archive=str(source_data.get("archive", "")),
                source_sha256=str(source_data.get("sha256", "")),
                build_script=build_script,
                build_environment=build_environment,
                manifest=manifest,
            )

        return packages

    def _load_profiles(self) -> dict[str, Profile]:
        profiles: dict[str, Profile] = {}

        for manifest in sorted(self.profiles_dir.rglob("profile.toml")):
            data = load_toml(manifest)
            profile_data = data.get("profile", {})
            prepare_data = data.get("prepare", {})
            chroot_data = data.get("chroot", {})
            image_data = data.get("image", {})

            profile_id = str(profile_data.get("id", "")).strip()
            if not profile_id:
                fail(f"Profile id is missing in {manifest.relative_to(ROOT)}")
            if profile_id in profiles:
                fail(f"Duplicate profile id: {profile_id}")

            run_value = str(image_data.get("run", "")).strip()
            run_script = ROOT / run_value if run_value else None

            chroot_value = str(chroot_data.get("root", "")).strip()
            chroot_root = ROOT / chroot_value if chroot_value else None

            profiles[profile_id] = Profile(
                id=profile_id,
                name=str(profile_data.get("name", profile_id)),
                status=str(profile_data.get("status", "planned")),
                description=str(profile_data.get("description", "")),
                parent=str(profile_data.get("parent", "")).strip(),
                packages=tuple(
                    str(item) for item in profile_data.get("packages", [])
                ),
                prepare_steps=tuple(
                    ROOT / str(item)
                    for item in prepare_data.get("steps", [])
                ),
                chroot_root=chroot_root,
                image_steps=tuple(
                    ROOT / str(item)
                    for item in image_data.get("steps", [])
                ),
                run_script=run_script,
                manifest=manifest,
            )

        return profiles

    def _validate_references(self) -> None:
        for package in self.packages.values():
            if not package.source_urls:
                fail(f"Package {package.name} has no source URL")

            if not package.source_archive:
                fail(f"Package {package.name} has no source archive name")

            if not package.source_sha256:
                fail(f"Package {package.name} has no source SHA256")

            for dependency in package.dependencies:
                if dependency not in self.packages:
                    fail(
                        f"Package {package.name} depends on unknown package "
                        f"{dependency}"
                    )

        for profile in self.profiles.values():
            if profile.parent and profile.parent not in self.profiles:
                fail(
                    f"Profile {profile.id} has unknown parent {profile.parent}"
                )

            for package_name in profile.packages:
                if package_name not in self.packages:
                    fail(
                        f"Profile {profile.id} references unknown package "
                        f"{package_name}"
                    )

            for step in (*profile.prepare_steps, *profile.image_steps):
                if not step.is_file():
                    fail(
                        f"Profile step not found for {profile.id}: "
                        f"{step.relative_to(ROOT)}"
                    )

            if profile.run_script and not profile.run_script.is_file():
                fail(
                    f"Run script not found for profile {profile.id}: "
                    f"{profile.run_script.relative_to(ROOT)}"
                )

    def package(self, name: str) -> Package:
        try:
            return self.packages[name]
        except KeyError:
            fail(f"Unknown package: {name}")

    def profile(self, profile_id: str) -> Profile:
        try:
            return self.profiles[profile_id]
        except KeyError:
            fail(f"Unknown profile: {profile_id}")

    def profile_chain(self, profile_id: str) -> list[Profile]:
        result: list[Profile] = []
        visiting: set[str] = set()

        def visit(current_id: str) -> None:
            if current_id in visiting:
                fail(f"Profile inheritance cycle detected at: {current_id}")

            visiting.add(current_id)
            profile = self.profile(current_id)

            if profile.parent:
                visit(profile.parent)

            result.append(profile)
            visiting.remove(current_id)

        visit(profile_id)
        return result

    def profile_packages(self, profile_id: str) -> list[str]:
        result: list[str] = []

        for profile in self.profile_chain(profile_id):
            for package_name in profile.packages:
                if package_name not in result:
                    result.append(package_name)

        return result

    def profile_prepare_steps(self, profile_id: str) -> list[Path]:
        result: list[Path] = []

        for profile in self.profile_chain(profile_id):
            for step in profile.prepare_steps:
                if step not in result:
                    result.append(step)

        return result

    def profile_chroot_root(self, profile_id: str) -> Path | None:
        resolved: Path | None = None

        for profile in self.profile_chain(profile_id):
            if profile.chroot_root is not None:
                resolved = profile.chroot_root

        return resolved

    def build_order(self, package_names: Iterable[str]) -> list[str]:
        order: list[str] = []
        temporary: set[str] = set()
        permanent: set[str] = set()

        def visit(name: str) -> None:
            if name in permanent:
                return
            if name in temporary:
                fail(f"Package dependency cycle detected at: {name}")

            package = self.package(name)
            temporary.add(name)

            for dependency in package.dependencies:
                visit(dependency)

            temporary.remove(name)
            permanent.add(name)
            order.append(name)

        for package_name in package_names:
            visit(package_name)

        return order

    def doctor(self) -> int:
        print(f"Veyr Forge for Veyr {self.version}")
        print(f"Repository: {ROOT}")
        print(f"Architecture: {self.arch}")
        print(f"Python: {sys.version.split()[0]}")

        expected = tuple(
            int(part) for part in self.min_python.split(".")[:2]
        )

        if sys.version_info[:2] < expected:
            print(red(f"[FAIL] Python {self.min_python}+ is required"))
            return 1

        ok(f"Python {self.min_python}+ available")

        commands = list(
            self.config.get("host", {}).get("required_commands", [])
        )

        for package in self.packages.values():
            if package.build_environment == "host":
                commands.extend(package.required_commands)

        missing: list[str] = []

        for command in sorted(set(str(item) for item in commands)):
            if shutil.which(command):
                print(f"  {green('✓')} {command}")
            else:
                print(f"  {red('✗')} {command}")
                missing.append(command)

        if missing:
            warn("Missing host commands: " + ", ".join(missing))
            print("Run: make deps")
            return 1

        ok("Host build environment looks ready")
        return 0

    def list_packages(self) -> None:
        print(f"Packages ({len(self.packages)}):")

        for package in sorted(
            self.packages.values(),
            key=lambda item: (item.category, item.name),
        ):
            print(
                f"  {package.name:<20} {package.version:<12} "
                f"[{package.category}/{package.build_environment}]  "
                f"{package.description}"
            )

    def list_profiles(self) -> None:
        print(f"Profiles ({len(self.profiles)}):")

        for profile in sorted(self.profiles.values(), key=lambda item: item.id):
            parent = f", parent={profile.parent}" if profile.parent else ""
            print(
                f"  {profile.id:<18} [{profile.status}] "
                f"{profile.name}{parent}"
            )
            if profile.description:
                print(f"                     {profile.description}")

    def info_package(self, name: str) -> None:
        package = self.package(name)

        print(f"Package:      {package.name}")
        print(f"Version:      {package.version}")
        print(f"Category:     {package.category}")
        print(f"Environment:  {package.build_environment}")
        print(f"Description:  {package.description}")
        print(f"Manifest:     {package.manifest.relative_to(ROOT)}")
        print("Sources:")
        for source_url in package.source_urls:
            print(f"  - {source_url}")
        print(f"Archive:      {package.source_archive}")
        print(f"SHA256:       {package.source_sha256}")
        print(
            "Dependencies: "
            + (", ".join(package.dependencies) if package.dependencies else "(none)")
        )
        print("Outputs:")
        for output in package.outputs:
            print(f"  - {output.relative_to(ROOT)}")

    def info_profile(self, profile_id: str) -> None:
        profile = self.profile(profile_id)
        print(f"Profile:      {profile.id}")
        print(f"Name:         {profile.name}")
        print(f"Status:       {profile.status}")
        print(f"Parent:       {profile.parent or '(none)'}")
        print(f"Description:  {profile.description}")
        print(f"Manifest:     {profile.manifest.relative_to(ROOT)}")

        packages = self.profile_packages(profile_id)
        print("Packages:     " + (", ".join(packages) if packages else "(none)"))

        prepare_steps = self.profile_prepare_steps(profile_id)
        if prepare_steps:
            print("Prepare steps:")
            for step in prepare_steps:
                print(f"  - {step.relative_to(ROOT)}")

        chroot_root = self.profile_chroot_root(profile_id)
        if chroot_root is not None:
            print(f"Chroot root:  {chroot_root.relative_to(ROOT)}")

        if profile.image_steps:
            print("Image steps:")
            for step in profile.image_steps:
                print(f"  - {step.relative_to(ROOT)}")

    def graph(self, profile_id: str) -> None:
        package_names = self.profile_packages(profile_id)
        order = self.build_order(package_names)

        print(f"Build graph for profile '{profile_id}':")
        if not order:
            print("  (no packages yet)")
            return

        for index, name in enumerate(order, start=1):
            package = self.package(name)
            deps = ", ".join(package.dependencies) if package.dependencies else "none"
            print(
                f"  {index:>2}. {name} {package.version}  "
                f"env: {package.build_environment}  deps: {deps}"
            )

    def _source_path(self, package: Package) -> Path:
        return self.sources_dir / package.source_archive

    def fetch_package(self, name: str) -> Path:
        package = self.package(name)
        destination = self._source_path(package)
        destination.parent.mkdir(parents=True, exist_ok=True)

        if destination.is_file():
            actual = sha256_file(destination)
            if actual == package.source_sha256:
                ok(f"{package.name} source already verified")
                return destination

            warn(
                f"Checksum mismatch for cached {destination.name}; "
                "downloading again"
            )
            destination.unlink()

        log(f"Downloading {package.name} {package.version}")
        temporary = destination.with_suffix(destination.suffix + ".part")
        errors: list[str] = []

        for index, source_url in enumerate(package.source_urls, start=1):
            temporary.unlink(missing_ok=True)

            if len(package.source_urls) > 1:
                print(
                    f"  mirror {index}/{len(package.source_urls)}: {source_url}"
                )

            request = urllib.request.Request(
                source_url,
                headers={"User-Agent": f"Veyr-Forge/{self.version}"},
            )

            try:
                with (
                    urllib.request.urlopen(request, timeout=60) as response,
                    temporary.open("wb") as output,
                ):
                    shutil.copyfileobj(response, output)
            except Exception as exc:
                temporary.unlink(missing_ok=True)
                errors.append(f"{source_url}: {exc}")
                warn(f"Download failed from {source_url}: {exc}")
                continue

            actual = sha256_file(temporary)
            if actual != package.source_sha256:
                errors.append(
                    f"{source_url}: SHA256 mismatch (got {actual})"
                )
                warn(f"SHA256 mismatch from {source_url}")
                temporary.unlink(missing_ok=True)
                continue

            temporary.replace(destination)
            ok(f"Downloaded and verified {package.source_archive}")
            return destination

        rendered = "\n".join(f"  - {item}" for item in errors)
        fail(
            f"Unable to obtain a verified source for {package.name}.\n"
            f"Expected SHA256: {package.source_sha256}\n"
            f"Attempts:\n{rendered}"
        )

    def fetch_packages(self, package_names: Iterable[str]) -> None:
        for package_name in self.build_order(package_names):
            self.fetch_package(package_name)

    def _safe_extract(self, archive: Path, destination: Path) -> Path:
        remove_tree_contents(destination)

        try:
            with tarfile.open(archive, mode="r:*") as tar:
                root = destination.resolve()

                for member in tar.getmembers():
                    member_path = (destination / member.name).resolve()
                    try:
                        member_path.relative_to(root)
                    except ValueError:
                        fail(
                            f"Unsafe path in archive {archive.name}: {member.name}"
                        )

                try:
                    tar.extractall(destination, filter="fully_trusted")
                except TypeError:
                    tar.extractall(destination)
        except tarfile.TarError as exc:
            fail(f"Unable to extract {archive.name}: {exc}")

        entries = list(destination.iterdir())
        if len(entries) == 1 and entries[0].is_dir():
            return entries[0]

        return destination

    def _dependency_fingerprints(self, package: Package) -> bytes:
        data: list[str] = []

        for dependency_name in package.dependencies:
            dependency = self.package(dependency_name)
            state_file = self._state_file(dependency)
            fingerprint = "missing"

            if state_file.is_file():
                try:
                    state = json.loads(state_file.read_text(encoding="utf-8"))
                    fingerprint = str(state.get("fingerprint", "missing"))
                except (json.JSONDecodeError, OSError):
                    fingerprint = "invalid"

            data.append(f"{dependency_name}:{fingerprint}")

        return "\n".join(data).encode("utf-8")

    def _support_files_fingerprint(self) -> bytes:
        digest = hashlib.sha256()
        support_dir = ROOT / "scripts" / "lib"

        if support_dir.is_dir():
            for path in sorted(support_dir.rglob("*.sh")):
                digest.update(str(path.relative_to(ROOT)).encode("utf-8"))
                digest.update(path.read_bytes())

        return digest.hexdigest().encode("ascii")

    def _package_fingerprint(self, package: Package, source: Path) -> str:
        environment_support = b""

        if package.build_environment == "chroot":
            runner = ROOT / "scripts" / "run-chroot-package.sh"
            if runner.is_file():
                environment_support = runner.read_bytes()

        return hash_bytes(
            package.manifest.read_bytes(),
            package.build_script.read_bytes(),
            sha256_file(source).encode("ascii"),
            self.arch.encode("utf-8"),
            package.build_environment.encode("utf-8"),
            self._dependency_fingerprints(package),
            self._support_files_fingerprint(),
            environment_support,
        )

    def _state_file(self, package: Package) -> Path:
        return self.state_dir / f"{package.name}.json"

    def _is_cached(self, package: Package, fingerprint: str) -> bool:
        state_file = self._state_file(package)

        if not state_file.is_file():
            return False

        if not package.outputs or not all(path.exists() for path in package.outputs):
            return False

        try:
            state = json.loads(state_file.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            return False

        return state.get("fingerprint") == fingerprint

    def _write_state(self, package: Package, fingerprint: str) -> None:
        state_file = self._state_file(package)
        state_file.parent.mkdir(parents=True, exist_ok=True)
        state_file.write_text(
            json.dumps(
                {
                    "package": package.name,
                    "version": package.version,
                    "architecture": self.arch,
                    "environment": package.build_environment,
                    "fingerprint": fingerprint,
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )

    def _host_build_environment(
        self,
        package: Package,
        source_archive: Path,
        source_dir: Path,
        package_build_dir: Path,
        package_out: Path,
        jobs: int,
    ) -> dict[str, str]:
        env = os.environ.copy()
        env.update(
            {
                "VEYR_ROOT": str(ROOT),
                "VEYR_VERSION": self.version,
                "VEYR_ARCH": self.arch,
                "VEYR_PACKAGE_NAME": package.name,
                "VEYR_PACKAGE_VERSION": package.version,
                "VEYR_SOURCE_ARCHIVE": str(source_archive),
                "VEYR_SOURCE_DIR": str(source_dir),
                "VEYR_BUILD_DIR": str(package_build_dir),
                "VEYR_PACKAGE_OUT": str(package_out),
                "VEYR_JOBS": str(jobs),
                "VEYR_BUILD_ENVIRONMENT": "host",
            }
        )
        return env

    def _build_host_package(
        self,
        package: Package,
        source_archive: Path,
        jobs: int,
    ) -> None:
        package_build_dir = self.build_dir / "packages" / package.name
        source_root = package_build_dir / "src"
        source_dir = self._safe_extract(source_archive, source_root)
        package_out = self.out_dir / "packages" / package.name
        package_out.mkdir(parents=True, exist_ok=True)

        env = self._host_build_environment(
            package,
            source_archive,
            source_dir,
            package_build_dir,
            package_out,
            jobs,
        )

        result = subprocess.run(
            [str(package.build_script)],
            cwd=source_dir,
            env=env,
            check=False,
        )

        if result.returncode != 0:
            fail(
                f"Build failed for package {package.name} "
                f"(exit code {result.returncode})"
            )

    def _build_chroot_package(
        self,
        package: Package,
        source_archive: Path,
        jobs: int,
        profile_id: str | None,
    ) -> None:
        if profile_id is None:
            fail(
                f"Package {package.name} must be built inside a profile chroot. "
                "Use: ./veyr build --profile temporary-alpha4"
            )

        chroot_root = self.profile_chroot_root(profile_id)
        if chroot_root is None:
            fail(f"Profile {profile_id} has no configured chroot root")

        chroot_root = ensure_within_root(chroot_root)
        if not chroot_root.is_dir():
            fail(
                f"Chroot root is not prepared for {package.name}: "
                f"{chroot_root.relative_to(ROOT)}"
            )

        source_root = chroot_root / "sources" / package.name
        source_dir = self._safe_extract(source_archive, source_root)

        runner = ROOT / "scripts" / "run-chroot-package.sh"
        if not runner.is_file():
            fail("Chroot package runner is missing: scripts/run-chroot-package.sh")

        env = os.environ.copy()
        env.update(
            {
                "VEYR_VERSION": self.version,
                "VEYR_ARCH": self.arch,
            }
        )

        result = subprocess.run(
            [
                str(runner),
                str(chroot_root),
                str(source_dir),
                str(package.build_script),
                package.name,
                package.version,
                str(jobs),
                "veyr-chroot-v1",
            ],
            cwd=ROOT,
            env=env,
            check=False,
        )

        if result.returncode != 0:
            fail(
                f"Chroot build failed for package {package.name} "
                f"(exit code {result.returncode})"
            )

    def _verify_outputs(self, package: Package) -> None:
        missing_outputs = [path for path in package.outputs if not path.exists()]

        if not missing_outputs:
            return

        rendered = "\n".join(
            f"  - {path.relative_to(ROOT)}" for path in missing_outputs
        )
        fail(
            f"Package {package.name} did not create declared outputs:\n{rendered}"
        )

    def build_package(
        self,
        name: str,
        rebuild: bool = False,
        profile_id: str | None = None,
    ) -> None:
        package = self.package(name)
        source_archive = self.fetch_package(name)
        fingerprint = self._package_fingerprint(package, source_archive)

        if not rebuild and self._is_cached(package, fingerprint):
            ok(f"{package.name} {package.version} is already built")
            return

        jobs = max(1, os.cpu_count() or 1)

        log(
            f"Building {package.name} {package.version} "
            f"[{package.build_environment}]"
        )

        if package.build_environment == "host":
            self._build_host_package(package, source_archive, jobs)
        else:
            self._build_chroot_package(
                package,
                source_archive,
                jobs,
                profile_id,
            )

        self._verify_outputs(package)
        self._write_state(package, fingerprint)
        ok(f"Built {package.name} {package.version}")

    def build_packages(
        self,
        package_names: Iterable[str],
        rebuild: bool = False,
        profile_id: str | None = None,
    ) -> None:
        for package_name in self.build_order(package_names):
            self.build_package(
                package_name,
                rebuild=rebuild,
                profile_id=profile_id,
            )

    def _run_steps(self, steps: Iterable[Path], label: str) -> None:
        for step in steps:
            log(f"{label}: {step.relative_to(ROOT)}")
            result = subprocess.run([str(step)], cwd=ROOT, check=False)

            if result.returncode != 0:
                fail(f"{label} failed: {step.relative_to(ROOT)}")

    def build_profile(self, profile_id: str, rebuild: bool = False) -> None:
        package_names = self.profile_packages(profile_id)
        order = self.build_order(package_names)
        prepare_steps = self.profile_prepare_steps(profile_id)

        prepared = False
        entered_chroot_stage = False

        for package_name in order:
            package = self.package(package_name)

            if package.build_environment == "chroot":
                if not prepared:
                    if not prepare_steps:
                        fail(
                            f"Profile {profile_id} contains chroot packages but "
                            "has no prepare steps"
                        )

                    self._run_steps(prepare_steps, "Prepare step")
                    prepared = True

                entered_chroot_stage = True
            elif entered_chroot_stage:
                fail(
                    f"Invalid build graph for {profile_id}: host package "
                    f"{package.name} appears after the chroot stage began"
                )

            self.build_package(
                package_name,
                rebuild=rebuild,
                profile_id=profile_id,
            )

        if not entered_chroot_stage and prepare_steps:
            log(
                f"Profile {profile_id} has prepare steps but no chroot packages; "
                "prepare stage was not needed"
            )

        ok(f"Build profile '{profile_id}' completed")

    def image(self, profile_id: str, rebuild: bool = False) -> None:
        profile = self.profile(profile_id)

        if profile.status != "active":
            fail(
                f"Profile '{profile_id}' is {profile.status}; "
                "only active profiles can produce images"
            )

        self.build_profile(profile_id, rebuild=rebuild)

        if not profile.image_steps:
            fail(f"Profile '{profile_id}' has no image steps")

        self._run_steps(profile.image_steps, "Image step")
        ok(f"Image profile '{profile_id}' completed")

    def run(self, profile_id: str) -> None:
        profile = self.profile(profile_id)

        if profile.run_script is None:
            fail(f"Profile '{profile_id}' has no run script")

        result = subprocess.run(
            [str(profile.run_script)],
            cwd=ROOT,
            check=False,
        )

        if result.returncode != 0:
            fail(f"Run command failed for profile '{profile_id}'")

    def clean(self, include_sources: bool = False) -> None:
        log("Cleaning build and output directories")
        remove_tree_contents(self.build_dir)
        remove_tree_contents(self.out_dir)
        (self.build_dir / ".gitkeep").touch()
        (self.out_dir / ".gitkeep").touch()

        if include_sources:
            log("Cleaning downloaded sources")
            source_root = ROOT / "sources"
            remove_tree_contents(source_root)
            (source_root / ".gitkeep").touch()

        ok("Clean complete")


def select_packages(
    forge: Forge,
    package_name: str | None,
    profile_id: str | None,
) -> list[str]:
    if package_name and profile_id:
        fail("Choose either a package or --profile, not both")

    if profile_id:
        return forge.profile_packages(profile_id)

    if package_name:
        forge.package(package_name)
        return [package_name]

    fail("Specify a package name or --profile PROFILE")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="veyr",
        description="Veyr Forge - build orchestration for the Veyr Linux distribution",
    )

    parser.add_argument(
        "--version",
        action="store_true",
        help="show Veyr/Forge version",
    )

    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("doctor", help="check the host build environment")

    list_parser = subparsers.add_parser("list", help="list packages or profiles")
    list_parser.add_argument("kind", choices=("packages", "profiles"))

    info_parser = subparsers.add_parser(
        "info", help="show package or profile information"
    )
    info_parser.add_argument("kind", choices=("package", "profile"))
    info_parser.add_argument("name")

    graph_parser = subparsers.add_parser(
        "graph", help="show build order for a profile"
    )
    graph_parser.add_argument("profile")

    fetch_parser = subparsers.add_parser(
        "fetch", help="download and verify sources"
    )
    fetch_parser.add_argument("package", nargs="?")
    fetch_parser.add_argument("--profile")

    build_cmd = subparsers.add_parser(
        "build", help="build a package or profile"
    )
    build_cmd.add_argument("package", nargs="?")
    build_cmd.add_argument("--profile")
    build_cmd.add_argument("--rebuild", action="store_true")

    image_parser = subparsers.add_parser(
        "image", help="build an image profile"
    )
    image_parser.add_argument("profile")
    image_parser.add_argument("--rebuild", action="store_true")

    run_parser = subparsers.add_parser(
        "run", help="run a profile in its configured VM"
    )
    run_parser.add_argument("profile")

    clean_parser = subparsers.add_parser(
        "clean", help="remove generated build artifacts"
    )
    clean_parser.add_argument(
        "--sources",
        action="store_true",
        help="also delete downloaded sources",
    )

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    try:
        forge = Forge()

        if args.version:
            print(
                f"Veyr {forge.version} / Forge format "
                f"{forge.config.get('project', {}).get('format', 1)}"
            )
            return 0

        if args.command is None:
            parser.print_help()
            return 0

        if args.command == "doctor":
            return forge.doctor()

        if args.command == "list":
            if args.kind == "packages":
                forge.list_packages()
            else:
                forge.list_profiles()
            return 0

        if args.command == "info":
            if args.kind == "package":
                forge.info_package(args.name)
            else:
                forge.info_profile(args.name)
            return 0

        if args.command == "graph":
            forge.graph(args.profile)
            return 0

        if args.command == "fetch":
            packages = select_packages(
                forge,
                args.package,
                args.profile,
            )
            forge.fetch_packages(packages)
            return 0

        if args.command == "build":
            if args.profile:
                if args.package:
                    fail("Choose either a package or --profile, not both")
                forge.build_profile(args.profile, rebuild=args.rebuild)
            else:
                packages = select_packages(forge, args.package, None)
                forge.build_packages(packages, rebuild=args.rebuild)
            return 0

        if args.command == "image":
            forge.image(args.profile, rebuild=args.rebuild)
            return 0

        if args.command == "run":
            forge.run(args.profile)
            return 0

        if args.command == "clean":
            forge.clean(include_sources=args.sources)
            return 0

        fail(f"Unknown command: {args.command}")

    except ForgeError as exc:
        print(f"{red('[ERROR]')} {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nInterrupted.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())