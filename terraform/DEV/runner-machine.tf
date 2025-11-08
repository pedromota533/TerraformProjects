# Security Group for Runner Machine
resource "aws_security_group" "runner_sg" {
  name        = "runner-sg-${var.environment}"
  description = "Security group for Ansible managed runner node"

  # SSH access only from Ansible Control Node
  ingress {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    security_groups   = [aws_security_group.ansible_sg.id]
    description       = "SSH access from Ansible control node"
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
    key_name      = "ansible_ec2_keypare"

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