# Dependencies Folder

## Purpose
This folder contains configuration files and dependencies that need to be copied to remote runner hosts.

## Contents
- JSON configuration files
- Environment configurations
- Any other dependency files required by the runners

## Usage
All files in this directory will be automatically copied to `/tmp/dependencies/` on target hosts when running `playbook.yml`.