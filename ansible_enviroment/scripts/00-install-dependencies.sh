#!/bin/bash

set -euo pipefail

# ============================================================================
# Dependency Installation Script for GitHub Actions Runner
# ============================================================================

echo "Installing GitHub Runner Dependencies..."

# Update system packages
sudo apt-get update -y -q >/dev/null 2>&1

# Install essential tools quietly
sudo apt-get install -y -q curl tar git coreutils >/dev/null 2>&1

# Install additional useful tools (optional, don't fail if unavailable)
sudo apt-get install -y -q jq wget unzip >/dev/null 2>&1 || true

# Verify critical commands
commands_to_check=(curl tar git sha256sum)
all_ok=true

for cmd in "${commands_to_check[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "ERROR: $cmd not found"
        all_ok=false
    fi
done

if $all_ok; then
    echo "All dependencies installed successfully"
    exit 0
else
    echo "ERROR: Some dependencies failed to install"
    exit 1
fi
