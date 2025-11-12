# Root outputs - exposes module outputs

# EC2 Infrastructure outputs
output "runner_public_ips" {
  description = "Public IP addresses of runner instances"
  value       = module.ec2_infrastructure.runner_public_ips
}

output "runner_private_ips" {
  description = "Private IP addresses of runner instances"
  value       = module.ec2_infrastructure.runner_private_ips
}

output "runner_instance_ids" {
  description = "Instance IDs of runners"
  value       = module.ec2_infrastructure.runner_instance_ids
}

output "key_pair_name" {
  description = "SSH key pair name"
  value       = module.ec2_infrastructure.key_pair_name
}

output "ami_info" {
  description = "AMI information used for instances"
  value       = module.ec2_infrastructure.ami_info
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.ec2_infrastructure.vpc_id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = module.ec2_infrastructure.subnet_id
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.ec2_infrastructure.security_group_id
}

# Config Generator output
output "config_file_path" {
  description = "Path to generated config.ini file"
  value       = "${path.root}/../config/config.ini"
}
