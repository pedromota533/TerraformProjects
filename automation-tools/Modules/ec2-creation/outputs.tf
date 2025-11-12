# Outputs do módulo ec2-creation

output "runner_public_ips" {
  description = "Public IP addresses of runner instances"
  value       = aws_instance.runner[*].public_ip
}

output "runner_private_ips" {
  description = "Private IP addresses of runner instances"
  value       = aws_instance.runner[*].private_ip
}

output "runner_instance_ids" {
  description = "Instance IDs of runners"
  value       = aws_instance.runner[*].id
}

output "key_pair_name" {
  description = "SSH key pair name"
  value       = data.aws_key_pair.runner.key_name
}

output "ami_info" {
  description = "AMI information used for instances"
  value = {
    id            = data.aws_ami.ubuntu.id
    name          = data.aws_ami.ubuntu.name
    description   = data.aws_ami.ubuntu.description
    creation_date = data.aws_ami.ubuntu.creation_date
  }
}

