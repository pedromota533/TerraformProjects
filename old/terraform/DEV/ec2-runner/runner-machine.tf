# Security Group for Runner Machine
resource "aws_security_group" "runner_sg" {
  name        = "runner-sg-${var.environment}"
  description = "Security group for Ansible managed runner node"
  vpc_id      = aws_vpc.main_vpc.id  # ✅ Add this!
  # SSH access only from Ansible Control Node
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"  # -1 means all protocols
    security_groups = [aws_security_group.ansible_sg.id]
    description     = "All traffic from Ansible control node"
  }
  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "runner-sg-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Role        = "Ansible-Managed"
  }
}

resource "aws_instance" "machine_runner" {

    ami           = data.aws_ami.amazon_linux.id
    instance_type = "t2.micro"
    key_name      = "aws_permision_file_work"

    subnet_id     = aws_subnet.main_subnet.id
    # Usa a VPC/subnet default da região
    associate_public_ip_address = true

    # Security group
    vpc_security_group_ids = [aws_security_group.runner_sg.id]

    # User data
    user_data = <<-EOF
    #!/bin/bash
    yum update -y

    # Setup ansible user (from script)
    ${file("${path.module}/../../scripts/runner/setup-user.sh")}
    EOF

    tags = {
      Name        = "Runner-Machine-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Role        = "Ansible-Managed"
    }

}

//Extract the needed information about the runner
output "runner_private_ip" {
  description = "Runner Machine Private Ip"
  value = aws_instance.machine_runner.private_ip
}

output "runner_instance_id" {
  description = "Runner Machine Instance ID"
  value = aws_instance.machine_runner.id
}


