variable "ansible_ssh_key_path" {
  description = "Path to SSH private key file for Ansible"
  type        = string
  default     = "~/.ssh/aws_permision_file_work.pem"
}

variable "ansible_user" {
  description = "SSH user for Ansible connections"
  type        = string
  default     = "ec2-user"
}

variable "ansible_python_interpreter" {
  description = "Python interpreter path on remote hosts"
  type        = string
  default     = "/usr/bin/python3.8"
}

# GitHub Runner Configuration Variables
variable "github_repo_url" {
  description = "GitHub repository URL for the runner"
  type        = string
  default     = "https://github.com/pedromota533/TerraformProjects"
}

variable "github_runner_token" {
  description = "GitHub runner registration token (sensitive)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_runner_version" {
  description = "GitHub Actions runner version"
  type        = string
  default     = "2.329.0"
}

variable "github_runner_dir" {
  description = "Installation directory for GitHub Actions runner"
  type        = string
  default     = "/home/ec2-user/actions-runner"
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
