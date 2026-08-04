SHELL := /usr/bin/env bash

.PHONY: all
all: alpha1

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
	./veyr graph base-alpha1

.PHONY: bootstrap-graph
bootstrap-graph:
	./veyr graph bootstrap

.PHONY: fetch
fetch:
	./veyr fetch --profile base-alpha1

.PHONY: busybox
busybox:
	./veyr build busybox

.PHONY: kernel
kernel:
	./veyr build linux

.PHONY: bootstrap
bootstrap:
	./veyr image bootstrap

.PHONY: bootstrap-run
bootstrap-run:
	./veyr run bootstrap

.PHONY: toolchain
toolchain:
	./veyr build --profile toolchain-alpha1

.PHONY: toolchain-test
toolchain-test:
	./scripts/build-toolchain-test.sh

.PHONY: alpha1
alpha1:
	./veyr image base-alpha1

.PHONY: run
run:
	./veyr run base-alpha1

.PHONY: run-alpha1
run-alpha1:
	./veyr run base-alpha1

.PHONY: clean
clean:
	./veyr clean

.PHONY: distclean
distclean:
	./veyr clean --sources