# Terraform and Provider Configuration
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.ec2_region
}

# Root variables - used by both modules

# EC2 Infrastructure variables
variable "number_of_machines" {
  description = "The number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "ec2_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "github_token" {
  description = "GitHub Runner Registration Token"
  type        = string
  sensitive   = true
}

# Ansible Configuration
variable "ansible_user" {
  description = "SSH user for Ansible connections"
  type        = string
  default     = "ubuntu"
}

variable "ansible_python_interpreter" {
  description = "Python interpreter path on remote hosts"
  type        = string
  default     = "/usr/bin/python3"
}

# GitHub Runner Configuration
variable "github_repo_url" {
  description = "GitHub repository URL for the runner"
  type        = string
  default     = "https://github.com/pedromota533/TerraformProjects"
}

variable "github_runner_version" {
  description = "GitHub Actions runner version"
  type        = string
  default     = "2.329.0"
}

variable "github_runner_dir" {
  description = "Installation directory for GitHub Actions runner"
  type        = string
  default     = "/home/ubuntu/actions-runner"
}

variable "github_runner_labels" {
  description = "Labels for the GitHub Actions runner"
  type        = string
  default     = "self-hosted,linux,x64"
}

variable "remove_runner" {
  description = "Set to true to remove runners instead of installing them"
  type        = bool
  default     = false
}
