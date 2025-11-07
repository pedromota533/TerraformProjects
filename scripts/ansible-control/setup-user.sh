#!/bin/bash
# Setup user for Ansible Control Node

# Create ansible user
useradd -m -s /bin/bash ansible

# Sudo apenas para comandos Ansible
echo "ansible ALL=(ALL) NOPASSWD: /usr/bin/ansible, /usr/bin/ansible-playbook, /usr/bin/ansible-pull, /usr/bin/ansible-galaxy, /usr/bin/ansible-vault" >> /etc/sudoers.d/ansible

chmod 0440 /etc/sudoers.d/ansible
