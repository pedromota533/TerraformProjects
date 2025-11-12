#!/bin/bash
# Python Update Script for Amazon Linux EC2 Instances
# Installs Python 3.9+ for Ansible compatibility

set -e

echo "Starting Python update for Amazon Linux..."

# Update system packages
sudo yum update -y

# Install Python 3.9 or 3.8
sudo amazon-linux-extras install python3.8 -y 2>/dev/null || true
sudo yum install python39 -y 2>/dev/null || sudo yum install python38 -y

# Install pip
sudo yum install python3-pip -y

echo "Python update completed!"
python3 --version
