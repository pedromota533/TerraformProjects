# This file is responsible with the creation of the ec2 instances

# Local variable to concatenate all scripts
locals {
  script_files = fileset("${path.module}/scripts", "*.sh")
  user_data_script = join("\n", [
    "#!/bin/bash",
    "set -e",
    "echo 'Running setup scripts...'",
    join("\n", [
      for script in local.script_files :
      file("${path.module}/scripts/${script}")
    ]),
    "echo 'All scripts completed successfully!'"
  ])
}

resource "aws_instance" "runner" {
  count = var.number_of_machines

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.runner.id]
  key_name               = data.aws_key_pair.runner.key_name
  user_data              = local.user_data_script

  tags = {
    Name = "github-runner-${count.index + 1}"
    Type = "GitHub-Runner"
  }
}

# Output individual IPs
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
