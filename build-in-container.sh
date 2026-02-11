#!/bin/bash

# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

set -e

# This script runs INSIDE the container
# It installs dependencies, prepares yap, and builds the package
#
# Usage (inside container): ./build-in-container.sh <deps-dir|none> <distro> <package-dir>

DEPS_DIR=$1
DISTRO=$2
PACKAGE_DIR=${3:-/project}

if [ -z "$DISTRO" ]; then
    echo "Usage: $0 <deps-dir|none> <distro> [package-dir]"
    exit 1
fi

echo "==> Building $PACKAGE_DIR for $DISTRO"

# Install Node.js (not available in default repos)
echo "==> Installing Curl and Node.js"
if [ -f /etc/debian_version ]; then
    apt-get update
    apt-get install -y ca-certificates gnupg wget
    mkdir -p /etc/apt/keyrings
    wget -qO- https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list
    apt-get update
    apt-get install -y curl nodejs
elif [ -f /etc/redhat-release ]; then
    yum install -y https://rpm.nodesource.com/pub_22.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm
    yum install -y curl nodejs
fi

# Install dependencies if provided
if [ "$DEPS_DIR" != "none" ] && [ -n "$DEPS_DIR" ]; then
    echo "==> Installing dependencies from $DEPS_DIR"
    
    if [ -f /etc/debian_version ]; then
        apt-get update
        find "$DEPS_DIR" -name '*.deb' -exec dpkg -i {} + || apt-get install -f -y
    elif [ -f /etc/redhat-release ]; then
        find "$DEPS_DIR" -name '*.rpm' -exec rpm -ivh --force {} +
    else
        echo "Error: Unknown distribution"
        exit 1
    fi
    echo "==> Dependencies installed"
fi

# Prepare yap
echo "==> Running yap prepare $DISTRO -g"
yap prepare "$DISTRO" -g

# Build package
echo "==> Running yap build $DISTRO $PACKAGE_DIR"
yap build "$DISTRO" "$PACKAGE_DIR"

echo "==> Build complete!"
