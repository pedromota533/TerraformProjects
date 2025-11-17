#!/bin/bash

set -euo pipefail

# ============================================================================
# Dependency Installation Script for GitHub Actions Runner
# ============================================================================

echo "Installing GitHub Runner Dependencies..."


# Wait for apt locks to be released
echo "Checking for apt locks..."
lock_wait_count=0
while fuser /var/lib/dpkg/lock-frontend 2>&1 || fuser /var/lib/apt/lists/lock 2>&1; do
    echo "Waiting for other apt processes to finish... (attempt $((++lock_wait_count)))"
    if [ $lock_wait_count -gt 60 ]; then
        echo "ERROR: Timed out waiting for apt locks after 5 minutes"
        exit 1
    fi
    sleep 5
done

# Update system packages (without sudo since we're already root via become: yes)
echo "Updating package lists..."
if ! apt-get update -y; then
    echo "ERROR: Failed to update package lists"
    exit 1
fi

# Install essential tools
echo "Installing essential packages..."
if ! apt-get install -y curl tar git coreutils; then
    echo "ERROR: Failed to install essential packages"
    exit 1
fi

# Install additional useful tools (optional, don't fail if unavailable)
echo "Installing optional packages..."
if ! apt-get install -y jq wget unzip; then
    echo "WARNING: Some optional packages failed to install (non-critical)"
fi

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
