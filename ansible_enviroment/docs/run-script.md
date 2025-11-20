# Run Script Documentation

## Overview

The `run` script is the main entry point for deploying GitHub Actions self-hosted runners to either AWS EC2 instances or Azure Virtual Machines. It handles environment setup, validation, and playbook execution.

## Usage

```bash
./run --aws|--azure [CONFIG_PATH]
```

### Required Arguments

| Argument | Description | Required |
|----------|-------------|----------|
| `--aws` | Deploy to AWS EC2 instances | Yes (one of --aws or --azure) |
| `--azure` | Deploy to Azure Virtual Machines | Yes (one of --aws or --azure) |

### Optional Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `CONFIG_PATH` | Path to configuration file | `../config/config.ini` |

## Examples

### AWS Deployments

```bash
# Deploy to AWS using default config
./run --aws

# Deploy to AWS with custom config
./run --aws /path/to/aws-config.ini

# Deploy to AWS with absolute path
./run --aws ~/configs/production.ini
```

### Azure Deployments

```bash
# Deploy to Azure using default config
./run --azure

# Deploy to Azure with custom config
./run --azure /path/to/azure-config.ini

# Deploy to Azure with absolute path
./run --azure ~/configs/staging.ini
```

## What the Script Does

1. **Argument Parsing**
   - Validates that `--aws` or `--azure` flag is provided
   - Sets the target playbook and inventory group
   - Accepts optional custom config path

2. **Configuration Validation**
   - Checks if config file exists
   - Validates that the appropriate inventory section exists (`[runners]` or `[runners-azure]`)
   - Verifies `github_runner_token` is set and not empty

3. **Environment Setup**
   - Checks for Python 3 installation
   - Creates or reuses Python virtual environment (`.venv/`)
   - Installs Ansible and dependencies

4. **Playbook Execution**
   - For AWS: Runs `playbook.yml` targeting `[runners]` group
   - For Azure: Runs `playbook-azure.yml` targeting `[runners-azure]` group

## Exit Codes

| Code | Meaning | Cause |
|------|---------|-------|
| 0 | Success | Ansible playbook completed successfully |
| 1 | No platform specified OR config not found | Missing `--aws`/`--azure` flag OR config file doesn't exist |
| 2 | Inventory section missing | `[runners-azure]` section not found when using `--azure` |
| 3 | Empty token | `github_runner_token` is empty in config file |
| 4 | Python 3 not installed | `python3` command not found |
| 5 | Virtual environment activation failed | Failed to activate `.venv/` |
| 6 | Ansible installation failed | Failed to install Ansible via pip |
| 7+ | Ansible playbook error | Playbook execution failed (code from ansible-playbook) |

## Error Messages and Solutions

### Error: No platform specified

```
ERROR: No platform specified
Usage: ./run --aws|--azure [CONFIG_PATH]
```

**Cause:** You didn't specify `--aws` or `--azure` flag

**Solution:**
```bash
./run --aws          # For AWS
./run --azure        # For Azure
```

---

### Error: Configuration file not found

```
ERROR: Configuration file not found at ../config/config.ini
Please run Terraform to generate the configuration first.
```

**Cause:** Config file doesn't exist at the specified path

**Solution:**
- For AWS: Run Terraform first to generate the config file
- For custom path: Verify the path is correct
```bash
ls -la ../config/config.ini           # Check if file exists
./run --aws /correct/path/config.ini  # Use correct path
```

---

### Error: [runners-azure] section not found

```
ERROR: [runners-azure] section not found in ../config/config.ini
Please add Azure runner configuration to the inventory file.
```

**Cause:** You used `--azure` but the config file doesn't have `[runners-azure]` section

**Solution:** Add the Azure section to your config file:
```ini
[runners-azure]
20.123.45.67
40.234.56.78

[runners-azure:vars]
ansible_ssh_private_key_file=~/.ssh/azure-key.pem
ansible_user=ubuntu
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3
github_runner_token=YOUR_TOKEN_HERE
```

---

### Error: github_runner_token is empty

```
ERROR: github_runner_token is empty in ../config/config.ini
Please set the GitHub runner token before running the playbook.
```

**Cause:** The `github_runner_token` field is not set or empty in the config file

**Solution:**
1. Get a token from GitHub:
   - Go to your GitHub organization/repo settings
   - Navigate to Actions → Runners → New self-hosted runner
   - Copy the token

2. Edit your config file:
```bash
vim ../config/config.ini
```

3. Set the token in the appropriate section:
```ini
# For AWS
[runners:vars]
github_runner_token=GHRT_YOUR_TOKEN_HERE

# For Azure
[runners-azure:vars]
github_runner_token=GHRT_YOUR_TOKEN_HERE
```

---

### Error: python3 is not installed

```
ERROR: python3 is not installed
```

**Cause:** Python 3 is not installed on your system

**Solution:** Install Python 3:
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install python3 python3-venv

# macOS
brew install python3

# Verify installation
python3 --version
```

---

### Error: Failed to create virtual environment

```
ERROR: Failed to create virtual environment
```

**Cause:** Python venv module is not available or insufficient permissions

**Solution:**
```bash
# Install venv module (Ubuntu/Debian)
sudo apt install python3-venv

# Check permissions
ls -la .venv/

# Remove and recreate
rm -rf .venv/
./run --aws
```

---

### Error: Failed to activate virtual environment

```
ERROR: Failed to activate virtual environment
```

**Cause:** Virtual environment is corrupted or permissions issue

**Solution:**
```bash
# Remove corrupted venv
rm -rf .venv/

# Run script again to recreate
./run --aws
```

---

### Error: Failed to install Ansible

```
ERROR: Failed to install Ansible
```

**Cause:** Network issues or pip is not working correctly

**Solution:**
```bash
# Check internet connectivity
ping pypi.org

# Try manual installation
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install ansible

# If successful, run script again
./run --aws
```

---

### Ansible playbook errors (exit codes 7+)

**Cause:** Issues during playbook execution (SSH failures, script errors, etc.)

**Common Solutions:**

1. **SSH Connection Failed:**
```bash
# Test SSH connectivity manually
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP

# Check SSH key permissions (must be 600)
chmod 600 ~/.ssh/your-key.pem

# Verify IP addresses in config file are correct
```

2. **Permission Denied:**
```bash
# Verify SSH key path in config is correct
# Verify ansible_user is correct (usually 'ubuntu')
```

3. **Runner installation failed:**
```bash
# SSH to the host and check logs
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_IP
tail -f /tmp/scripts/*.sh

# Check if dependencies were installed
which curl git jq
```

## Advanced Usage

### Targeting Specific Hosts

If you need to deploy to only specific hosts from your inventory:

```bash
# Activate the virtual environment first
source .venv/bin/activate

# Run playbook with --limit flag
ansible-playbook playbook.yml -i ../config/config.ini --limit 3.64.165.193

# Or for Azure
ansible-playbook playbook-azure.yml -i ../config/config.ini --limit 20.123.45.67
```

### Verbose Output

For debugging, add Ansible verbosity:

```bash
source .venv/bin/activate

# Verbose mode (-v, -vv, -vvv for more detail)
ansible-playbook playbook.yml -i ../config/config.ini -vv
```

### Dry Run (Check Mode)

Test what would change without making actual changes:

```bash
source .venv/bin/activate
ansible-playbook playbook.yml -i ../config/config.ini --check
```

## Environment Variables

The script uses the following environment variables:

| Variable | Set By | Purpose |
|----------|--------|---------|
| `GITHUB_TOKEN_ORG` | Ansible (from config) | GitHub runner registration token passed to scripts |

## Files Created by the Script

| Path | Description |
|------|-------------|
| `.venv/` | Python virtual environment directory |
| `requirements.txt` | Python package dependencies (auto-generated) |

## Troubleshooting Tips

### Script hangs during execution

**Possible causes:**
- SSH connection timeout
- Waiting for user input (shouldn't happen with proper SSH config)
- Long-running installation process

**Solution:**
```bash
# Cancel with Ctrl+C
# Check SSH connectivity
# Re-run with verbose mode to see where it hangs
```

### Multiple runs fail

**Solution:**
```bash
# Clean up virtual environment
rm -rf .venv/ requirements.txt

# Run again
./run --aws
```

### Changes to config not taking effect

**Cause:** Config file is cached or wrong file is being used

**Solution:**
```bash
# Verify you're editing the correct file
echo $PWD
cat ../config/config.ini | grep github_runner_token

# Explicitly specify the config path
./run --aws $(realpath ../config/config.ini)
```

## Best Practices

1. **Always specify the platform flag** - Don't rely on defaults
2. **Validate config file** - Check the file exists and has correct sections before running
3. **Test SSH connectivity** - Ensure you can SSH to targets manually first
4. **Keep tokens secure** - Never commit config files with tokens to git
5. **Use version control** - Track changes to config (without secrets) for easier rollback

## Related Documentation

- [Main README](../README.md) - Project overview and quick start
- [Configuration Guide](../README.md#configuration) - Config file structure
- [Troubleshooting](../README.md#troubleshooting) - General troubleshooting guide
