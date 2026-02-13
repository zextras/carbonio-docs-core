#!/bin/bash

# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

set -e

# This script runs INSIDE the container
# It installs dependencies, prepares yap, and builds the package
#
# Usage (inside container): ./build-in-container.sh <deps-dir|none> <distro> [package-subdir]

DEPS_DIR=$1
DISTRO=$2
PACKAGE_SUBDIR=$3

# If a subdirectory is provided, append it to /project, otherwise use /project
if [ -n "$PACKAGE_SUBDIR" ]; then
    PACKAGE_DIR="/project/$PACKAGE_SUBDIR"
else
    PACKAGE_DIR="/project"
fi

if [ -z "$DISTRO" ]; then
    echo "Usage: $0 <deps-dir|none> <distro> [package-dir]"
    exit 1
fi

echo "==> Building $PACKAGE_DIR for $DISTRO"

# Install dependencies if provided
if [ "$DEPS_DIR" != "none" ] && [ -n "$DEPS_DIR" ]; then
    echo "==> Installing dependencies from $DEPS_DIR"
    
    if [ -f /etc/debian_version ]; then
        apt-get update
        find "$DEPS_DIR" -name '*.deb' -exec dpkg -i {} + || apt-get install -f -y
    elif [ -f /etc/redhat-release ]; then
        # Enable EPEL for additional dependencies
        echo "==> Enabling EPEL repository"
        yum install -y epel-release
        
        # Use yum localinstall to resolve dependencies automatically
        echo "==> Installing RPM packages with dependency resolution"
        yum install -y "$DEPS_DIR"/*.rpm
    else
        echo "Error: Unknown distribution"
        exit 1
    fi
    echo "==> Dependencies installed"
fi

# Prepare yap
echo "==> Running yap prepare $DISTRO"
yap prepare "$DISTRO"

# Build package
echo "==> Running yap build $DISTRO $PACKAGE_DIR"
yap build "$DISTRO" "$PACKAGE_DIR"

echo "==> Build complete!"
