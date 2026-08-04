SHELL := /usr/bin/env bash

.PHONY: all
all:
	./scripts/build-all.sh

.PHONY: deps
deps:
	./scripts/setup-fedora.sh

.PHONY: fetch
fetch:
	./scripts/fetch-sources.sh

.PHONY: busybox
busybox:
	./scripts/build-busybox.sh

.PHONY: kernel
kernel:
	./scripts/build-kernel.sh

.PHONY: initramfs
initramfs:
	./scripts/build-initramfs.sh

.PHONY: iso
iso:
	./scripts/build-iso.sh

.PHONY: run
run:
	./scripts/run-qemu.sh

.PHONY: clean
clean:
	rm -rf build/*
	rm -rf out/*
	touch build/.gitkeep
	touch out/.gitkeep

.PHONY: distclean
distclean: clean
	rm -rf sources/*
	touch sources/.gitkeep