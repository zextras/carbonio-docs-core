# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

# Makefile for building carbonio-docs-core packages using YAP

# Configuration
YAP_IMAGE_PREFIX ?= docker.io/m0rf30/yap
YAP_VERSION ?= 1.48
CONTAINER_RUNTIME ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)

# Build options
TARGET ?= ubuntu-jammy
DEPS_DIR ?= none

# Computed values
YAP_IMAGE = $(YAP_IMAGE_PREFIX)-$(TARGET):$(YAP_VERSION)
CCACHE_DIR ?= $(CURDIR)/.ccache

# Container mount options
CONTAINER_OPTS = --rm -ti \
	-v $(CURDIR):/project \
	-v $(CURDIR)/artifacts:/artifacts \
	-v $(CCACHE_DIR):/root/.ccache \
	-e CCACHE_DIR=/root/.ccache \
	--entrypoint bash

# Add deps volume if provided
ifneq ($(DEPS_DIR),none)
DEPS_MOUNT = -v $(realpath $(DEPS_DIR)):/deps:ro
DEPS_ARG = /deps
else
DEPS_MOUNT =
DEPS_ARG = none
endif

.PHONY: help build build-rhel-only debug-build clean

.DEFAULT_GOAL := help

## help: Show this help message
help:
	@echo "Carbonio Docs Core - Build System"
	@echo ""
	@echo "Usage:"
	@echo "  make <target> [TARGET=<distro>] [DEPS_DIR=<path>]"
	@echo ""
	@echo "Targets:"
	@echo "  help           Show this help message"
	@echo "  build          Build all packages (poco + docs-core)"
	@echo "  build-rhel-only Build RHEL-only packages (Rocky only)"
	@echo "  debug-build    Start interactive shell in build container"
	@echo "  clean          Remove build artifacts"
	@echo ""
	@echo "Options:"
	@echo "  TARGET         Distribution target (default: ubuntu-jammy)"
	@echo "                 Supported: ubuntu-jammy, ubuntu-noble, rocky-8, rocky-9"
	@echo "  DEPS_DIR       Directory containing dependency packages (optional)"
	@echo "                 Example: ../carbonio-thirds/artifacts"
	@echo ""
	@echo "Examples:"
	@echo "  # Build without dependencies (Zextras devs with Artifactory access)"
	@echo "  make build TARGET=ubuntu-jammy"
	@echo ""
	@echo "  # Build with dependencies (community contributors)"
	@echo "  make build TARGET=ubuntu-jammy DEPS_DIR=../carbonio-thirds/artifacts"
	@echo ""
	@echo "  # Build RHEL-only packages for Rocky 8"
	@echo "  make build-rhel-only TARGET=rocky-8 DEPS_DIR=../carbonio-thirds/artifacts"
	@echo ""

## build: Build all packages (poco + docs-core)
build:
	@mkdir -p artifacts $(CCACHE_DIR)
	$(CONTAINER_RUNTIME) run $(CONTAINER_OPTS) $(DEPS_MOUNT) $(YAP_IMAGE) \
		/project/build-in-container.sh $(DEPS_ARG) $(TARGET) 2>&1 | tee build.log

## build-rhel-only: Build RHEL-only packages (Rocky only)
build-rhel-only:
	@if ! echo "$(TARGET)" | grep -q "^rocky-"; then \
		echo "Error: build-rhel-only is only supported for Rocky targets"; \
		echo "Current TARGET: $(TARGET)"; \
		exit 1; \
	fi
	@mkdir -p artifacts $(CCACHE_DIR)
	$(CONTAINER_RUNTIME) run $(CONTAINER_OPTS) $(DEPS_MOUNT) $(YAP_IMAGE) \
		/project/build-in-container.sh $(DEPS_ARG) $(TARGET) rhel-only 2>&1 | tee build-rhel-only.log

## debug-build: Start interactive shell in build container for manual debugging
debug-build:
	@mkdir -p artifacts $(CCACHE_DIR)
	@echo "Starting interactive shell in build container..."
	@echo "Container info:"
	@echo "  Image: $(YAP_IMAGE)"
	@echo "  Target: $(TARGET)"
	@echo "  Deps: $(DEPS_ARG)"
	@echo ""
	@echo "To run the build manually, execute:"
	@echo "  /project/build-in-container.sh $(DEPS_ARG) $(TARGET)"
	@echo ""
	$(CONTAINER_RUNTIME) run $(CONTAINER_OPTS) $(DEPS_MOUNT) $(YAP_IMAGE)

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf artifacts .ccache
	@echo "Clean complete!"
