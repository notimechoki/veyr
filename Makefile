SHELL := /usr/bin/env bash

.PHONY: all
all: image

.PHONY: deps
deps:
	./scripts/setup-fedora.sh

.PHONY: doctor
doctor:
	./veyr doctor

.PHONY: list
list:
	./veyr list packages
	@echo
	./veyr list profiles

.PHONY: graph
graph:
	./veyr graph bootstrap

.PHONY: fetch
fetch:
	./veyr fetch --profile bootstrap

.PHONY: busybox
busybox:
	./veyr build busybox

.PHONY: kernel
kernel:
	./veyr build linux

.PHONY: build
build:
	./veyr build --profile bootstrap

.PHONY: image
image:
	./veyr image bootstrap

.PHONY: run
run:
	./veyr run bootstrap

.PHONY: clean
clean:
	./veyr clean

.PHONY: distclean
distclean:
	./veyr clean --sources