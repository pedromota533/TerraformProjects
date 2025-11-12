data "terraform_remote_state" "runners" {
  backend = "local"

  config = {
    path = "../ec2-github-runners/state.tfstate"
  }
}

# Extract IPs and key pair info into local variables for easy access
locals {
  runner_public_ips  = data.terraform_remote_state.runners.outputs.runner_public_ips
  runner_private_ips = data.terraform_remote_state.runners.outputs.runner_private_ips
  key_pair_name      = data.terraform_remote_state.runners.outputs.key_pair_name
}

# Output them so you can see them after terraform apply
output "loaded_public_ips" {
  value       = local.runner_public_ips
  description = "Public IPs loaded from ec2-github-runners state"
}

output "loaded_private_ips" {
  value       = local.runner_private_ips
  description = "Private IPs loaded from ec2-github-runners state"
}