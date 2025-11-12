#!/bin/bash
# Setup user for Ansible Control Node

# Create ansible user
useradd -m -s /bin/bash ansible

# Setup SSH access for ansible user
mkdir -p /home/ansible/.ssh
chmod 700 /home/ansible/.ssh

# Copy authorized_keys from ec2-user (who gets the key from EC2 key pair)
cp /home/ec2-user/.ssh/authorized_keys /home/ansible/.ssh/authorized_keys
chmod 600 /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible/.ssh

# Sudo apenas para comandos Ansible
echo "ansible ALL=(ALL) NOPASSWD: /usr/bin/ansible, /usr/bin/ansible-playbook, /usr/bin/ansible-pull, /usr/bin/ansible-galaxy, /usr/bin/ansible-vault" >> /etc/sudoers.d/ansible
chmod 0440 /etc/sudoers.d/ansible
