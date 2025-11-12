#!/bin/bash
# Python Update Script for Ubuntu EC2 Instances
# Installs Python 3.10+ for Ansible compatibility

set -e

echo "Starting Python update for Ubuntu..."

# Update system packages
apt-get update -y

# Install Python 3 and pip (Ubuntu 22.04 comes with Python 3.10)
apt-get install -y python3 python3-pip

echo "Python update completed!"
echo "Python 3 location: $(which python3)"
python3 --version
