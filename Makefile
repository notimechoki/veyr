SHELL := /usr/bin/env bash

.PHONY: all
all: alpha2

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
	./veyr graph base-alpha2

.PHONY: bootstrap-graph
bootstrap-graph:
	./veyr graph bootstrap

.PHONY: alpha1-graph
alpha1-graph:
	./veyr graph base-alpha1

.PHONY: fetch
fetch:
	./veyr fetch --profile base-alpha2

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
toolchain-test: toolchain
	./scripts/build-toolchain-test.sh

.PHONY: alpha1
alpha1:
	./veyr image base-alpha1

.PHONY: run-alpha1
run-alpha1:
	./veyr run base-alpha1

.PHONY: temporary
temporary:
	./veyr build --profile temporary-alpha2

.PHONY: userspace-test
userspace-test: temporary
	./scripts/build-userspace-test.sh

.PHONY: alpha2
alpha2:
	./veyr image base-alpha2

.PHONY: run
run:
	./veyr run base-alpha2

.PHONY: run-alpha2
run-alpha2:
	./veyr run base-alpha2

.PHONY: clean
clean:
	./veyr clean

.PHONY: distclean
distclean:
	./veyr clean --sources