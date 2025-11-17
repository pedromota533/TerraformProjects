# Terraform GitHub Runner Constructor

Automated infrastructure-as-code solution for deploying GitHub Actions self-hosted runners on AWS EC2 using Terraform and Ansible.

## Documentation

- **[Ansible Environment](ansible_enviroment/README.md)** - Complete guide for Ansible deployment, scripts, and runner management

## Overview

This project provisions EC2 instances and automatically configures them as GitHub Actions runners. Infrastructure creation and configuration are fully automated through modular Terraform modules and Ansible playbooks.

## Requirements

- **Terraform** >= 1.0
- **Python 3** - For Ansible environment
- **AWS Account** - With appropriate credentials configured
- **GitHub Token** - Runner registration token from your repository
- **SSH Key** - For EC2 instance access

## Prerequisites Setup

### 1. Configure AWS Credentials

Choose one of the following methods:

**Option A: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
```

**Option B: AWS CLI Configuration** (recommended)
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region, and output format
```

This creates `~/.aws/credentials` file that Terraform will automatically use.

### 2. Set GitHub Token

```bash
export TF_VAR_github_token="your-github-token"
```

To get a GitHub token:
1. Go to your repository → Settings → Actions → Runners
2. Click "New self-hosted runner"
3. Copy the token from the configuration command

## Quick Start

```bash
# 1. Initialize and provision infrastructure
./run.sh init
./run.sh apply    # Uses TF_VAR_github_token from environment

# Or run the full workflow with confirmation prompts
./run.sh full

# 2. Deploy runners with Ansible
cd ansible_enviroment
./run
```

## Project Structure

```
terraform-github-contructor/
├── run.sh                      # Terraform wrapper script
├── automation-tools/           # Terraform root module
│   ├── main.tf                # Module orchestrator
│   ├── variables.tf           # Root variables
│   ├── output.tf              # Outputs
│   └── Modules/
│       ├── ec2-creation/      # EC2 infrastructure module
│       └── config-generation/ # Ansible config generator
├── ansible_enviroment/        # Ansible deployment
│   ├── run                    # Ansible wrapper script
│   ├── run-scripts.yml        # Main playbook
│   └── scripts/               # Shell scripts for runners
└── config/                    # Generated files (git-ignored)
    └── config.ini             # Ansible inventory
```

## Terraform Modules

### `ec2-creation`
Creates AWS infrastructure: VPC, subnets, internet gateway, security groups, key pairs, and EC2 instances.

**Outputs:** Runner IPs, key pair name, network configuration

### `config-generation`
Generates Ansible inventory file (`config/config.ini`) with EC2 IPs and runner configuration.

**Dependencies:** Requires `ec2-creation` outputs

## Commands

### `./run.sh` - Terraform Wrapper

```bash
./run.sh init      # Initialize Terraform
./run.sh plan      # Show execution plan
./run.sh apply     # Create infrastructure
./run.sh destroy   # Destroy all resources
./run.sh output    # Show outputs
./run.sh clean     # Clean Terraform files
```

### `ansible_enviroment/run` - Ansible Deployment

Automatically sets up Python venv, installs Ansible, and deploys runners to all EC2 instances. See `ansible_enviroment/README.md` for details.

## SSH Access to Runner Instances

After provisioning, you can SSH into any runner instance:

```bash
# Get runner IPs
./run.sh output

# SSH into a runner (uses key configured in Terraform)
ssh -i ~/.ssh/aws_permision_file_work.pem ubuntu@<RUNNER_IP>

# Or use the key path from config/config.ini
ssh -i $(grep ansible_ssh_private_key_file config/config.ini | cut -d'=' -f2) ubuntu@<RUNNER_IP>
```

**Note:** The SSH key pair (`aws_permision_file_work`) must exist in your AWS account and locally at the path specified in the Ansible config.

