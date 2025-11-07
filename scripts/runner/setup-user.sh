#!/bin/bash
# Setup user for Runner Machine (Managed Node)

# Create ansible user
useradd -m -s /bin/bash ansible

# Sudo completo (sem password)
echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible

chmod 0440 /etc/sudoers.d/ansible
