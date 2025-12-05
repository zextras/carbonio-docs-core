# Carbonio Docs Core

Carbonio Docs Core package build repository based on LibreOffice core components.

## Overview

This repository contains packaging definitions and build configurations for Carbonio Docs Core, which provides the core components for the Docs Server. The project is based on LibreOffice and is customized for the Zextras Carbonio suite.

## Components

- **docs-core**: Main LibreOffice-based core components for document processing
- **poco**: C++ class libraries for network-centric applications

## Build System

The project uses a Jenkins-based CI/CD pipeline with support for multiple Linux distributions:

### Supported Distributions
- Ubuntu Jammy (22.04)
- Ubuntu Noble (24.04) 
- Rocky Linux 8
- Rocky Linux 9

### Package Formats
- DEB packages for Ubuntu/Debian
- RPM packages for RHEL-based distributions

## Repository Structure

```
carbonio-docs-core/
├── .github/                 # GitHub configuration
│   ├── CODEOWNERS          # Code ownership rules
│   └── renovate.json       # Renovate bot configuration
├── docs-core/              # Main docs-core package
│   ├── PKGBUILD           # Arch Linux build script
│   ├── *.diff             # Build patches
│   └── *.in              # Configuration templates
├── poco/                  # POCO library package
│   └── PKGBUILD           # Arch Linux build script
├── rhel-only/             # RHEL-specific packages
│   ├── libepoxy/          # Epoxy OpenGL library
│   └── polib/             # Python PO file library
├── Jenkinsfile            # CI/CD pipeline definition
├── yap.json              # Build configuration
└── yap.json.license      # License information
```

## Building

### Prerequisites

The build system requires various development tools and libraries depending on the target distribution:

**For Ubuntu (APT):**
- Build tools: autoconf, automake, bison, clang, flex, etc.
- Libraries: carbonio-curl, carbonio-openssl, libepoxy, etc.

**For RHEL (YUM):**
- Build tools: automake, bison, clang, cmake, ninja, etc.
- Libraries: carbonio-curl, carbonio-openssl, graphite2, etc.

### Build Process

1. The Jenkins pipeline checks out the source code
2. Downloads external dependencies (dictionaries, help content, translations)
3. Applies patches and configuration
4. Builds using clang compiler with specific flags
5. Packages the results for distribution

## Configuration

- **Build Directory**: `/tmp/`
- **Output Directory**: `artifacts`
- **Installation Prefix**: `/opt/zextras/docs/`
- **Library Path**: `/opt/zextras/common/lib/`

## Dependencies

### Runtime Dependencies
- carbonio-curl
- carbonio-openssl
- libepoxy
- python3
- Various system libraries

### Build Dependencies
- clang/llvm toolchain
- cmake/ninja build system
- Various development libraries

## Repository Management

- **Owner**: Zextras <packages@zextras.com>
- **CI/CD**: Jenkins with GitHub integration
- **Dependency Updates**: Automated via Renovate bot
- **Artifact Repository**: Zextras Artifactory
