#!/bin/bash

set -euo pipefail

# ============================================================================
# Dependency Installation Script for GitHub Actions Runner
# ============================================================================
# This script installs all required dependencies for setting up
# GitHub Actions self-hosted runners on Ubuntu 22.04
# ============================================================================

echo "=========================================="
echo "Installing GitHub Runner Dependencies"
echo "=========================================="
echo ""

# Update system packages
echo "[1/4] Updating system packages..."
apt-get update -y -q

# Install essential tools
echo "[2/4] Installing essential tools (curl, tar, git)..."
apt-get install -y curl tar git

# Install coreutils (includes sha256sum)
echo "[3/4] Installing coreutils for hash validation..."
apt-get install -y coreutils

# Install additional useful tools
echo "[4/4] Installing additional tools (jq, wget, unzip)..."
apt-get install -y jq wget unzip || true

echo ""
echo "=========================================="
echo "Verifying installed commands..."
echo "=========================================="

# Verify installations
commands_to_check=(curl tar git sha256sum)
all_ok=true

for cmd in "${commands_to_check[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        version=$($cmd --version 2>&1 | head -n1 || echo "installed")
        echo "✓ $cmd: $version"
    else
        echo "✗ $cmd: NOT FOUND"
        all_ok=false
    fi
done

echo ""

if $all_ok; then
    echo "=========================================="
    echo "All dependencies installed successfully!"
    echo "=========================================="
    exit 0
else
    echo "=========================================="
    echo "ERROR: Some dependencies failed to install"
    echo "=========================================="
    exit 1
fi
