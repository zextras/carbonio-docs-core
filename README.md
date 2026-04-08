<!--
SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>

SPDX-License-Identifier: CC-BY-NC-SA-4.0
-->

# Carbonio Docs Core

Carbonio Docs Core is the build and packaging repository for the LibreOffice-based document processing engine that powers the Zextras Carbonio Docs collaborative editing feature. It compiles a headless, server-optimized LibreOffice core along with the POCO C++ networking libraries, producing DEB and RPM packages for deployment.

## Overview

This repository contains packaging definitions (PKGBUILD files) and build configurations for two main components:

- **docs-core** - A customized, headless LibreOffice core (v25.04.3) configured for server-side document processing. GUI, desktop integration, and optional features are disabled to produce a lean document conversion and rendering engine.
- **poco** - The POCO C++ class libraries (v1.14.1) for network-centric applications, required as a dependency by Carbonio Docs Server.

Packages are installed under `/opt/zextras/docs/` with LibreOfficeKit headers in `/opt/zextras/common/include/LibreOfficeKit` and PyUNO Python bindings symlinked into the system Python path.

## Quick Start

### Prerequisites

Building requires `yap` (version 1.48 or later) and `podman` installed on the host system. The PKGBUILD files declare all distribution-specific build and runtime dependencies, which are resolved automatically during the build process.

**Note:** This project requires YAP version 1.48 or later.

**Ubuntu (APT) build dependencies** include: autoconf, automake, bison, clang, flex, cmake, ninja-build, and various development libraries.

**RHEL (YUM) build dependencies** include: automake, bison, clang, cmake, ninja-build, gcc-c++, and various development libraries.

See the `PKGBUILD` files in `docs-core/` and `poco/` for the complete dependency lists.

### Dependencies

This project requires custom packages from
[carbonio-thirds](https://github.com/zextras/carbonio-thirds) (e.g.
`carbonio-openssl`, `carbonio-curl`). To build them locally:

```bash
git clone https://github.com/zextras/carbonio-thirds.git ../carbonio-thirds
cd ../carbonio-thirds
make build TARGET=ubuntu-noble
cd -
```

Then pass the artifacts directory when building this project (see below).

### Building Packages

```bash
# Build all packages for Ubuntu 24.04 (with local dependencies)
make build TARGET=ubuntu-noble DEPS_DIR=../carbonio-thirds/artifacts

# Build for Rocky Linux 9
make build TARGET=rocky-9 DEPS_DIR=../carbonio-thirds/artifacts

# Build RHEL-only packages (e.g., polib) for Rocky Linux 8
make build-rhel-only TARGET=rocky-8 DEPS_DIR=../carbonio-thirds/artifacts
```

### Supported Targets

- `ubuntu-jammy` - Ubuntu 22.04 LTS
- `ubuntu-noble` - Ubuntu 24.04 LTS
- `rocky-8` - Rocky Linux 8
- `rocky-9` - Rocky Linux 9

### Build Commands

- `make build` - Build all packages (poco + docs-core)
- `make build-rhel-only` - Build RHEL-only packages (Rocky only, skips Node.js installation)
- `make clean` - Remove build artifacts

Run `make help` to see all available options.

## Installation

These packages are distributed as part of the [Carbonio platform](https://zextras.com/carbonio). To install:

### Ubuntu (Jammy/Noble)

```bash
apt-get install <package-name>
```

### Rocky Linux (8/9)

```bash
yum install <package-name>
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for information on how to contribute to this project.

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details.
