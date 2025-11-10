#!/bin/bash

# This could be your template script

LOG_FILE="/var/log/ansible-setup.log"

echo "=== Ansible Control Node Setup ===" >> $LOG_FILE

echo "Setup started at: $(date)" >> $LOG_FILE

echo "Environment: ${ENVIRONMENT}" >> $LOG_FILE

echo "Setup completed successfully" >> $LOG_FILE

chmod 644 $LOG_FILE
