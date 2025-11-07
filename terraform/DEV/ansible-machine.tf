# Ansible Control Node
resource "aws_instance" "ansible_control" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  # Usa a VPC/subnet default da região
  associate_public_ip_address = true
  
  # Security group
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
  
  # User data para instalar Ansible
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install ansible2 -y

    # Setup ansible user (from script)
    ${file("${path.module}/../../scripts/ansible-control/setup-user.sh")}
  EOF
  
  tags = {
    Name        = "Ansible-Control-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Role        = "Ansible-Control"
  }
}

# Security Group para Ansible (usa VPC default)
resource "aws_security_group" "ansible_sg" {
  name        = "ansible-control-sg-${var.environment}"
  description = "Security group for Ansible control node"
  
  # SSH access apenas do teu IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
    description = "SSH access from Pedros IP"
  }
  
  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "ansible-control-sg-${var.environment}"
    Environment = var.environment
  }
}

# Outputs da máquina Ansible
output "ansible_instance_id" {
  description = "Ansible Control Node Instance ID"
  value       = aws_instance.ansible_control.id
}

output "ansible_public_ip" {
  description = "Ansible Control Node Public IP"
  value       = aws_instance.ansible_control.public_ip
}

output "ansible_private_ip" {
  description = "Ansible Control Node Private IP"
  value       = aws_instance.ansible_control.private_ip
}