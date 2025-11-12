# Main orchestrator - calls both modules

# Module 1: Create EC2 infrastructure
module "ec2_infrastructure" {
  source = "./Modules/ec2-creation"

  number_of_machines = var.number_of_machines
  ec2_region        = var.ec2_region
  github_token      = var.github_token
}

# Module 2: Generate Ansible config.ini
module "config_generator" {
  source = "./Modules/config-generation"

  # Inputs from ec2_infrastructure module
  runner_public_ips = module.ec2_infrastructure.runner_public_ips
  key_pair_name     = module.ec2_infrastructure.key_pair_name

  # Ansible and GitHub configuration
  ansible_user              = var.ansible_user
  ansible_python_interpreter = var.ansible_python_interpreter
  github_repo_url           = var.github_repo_url
  github_runner_token       = var.github_token
  github_runner_version     = var.github_runner_version
  github_runner_dir         = var.github_runner_dir
  github_runner_labels      = var.github_runner_labels
  remove_runner             = var.remove_runner
}
