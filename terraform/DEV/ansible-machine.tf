# Ansible Control Node
resource "aws_instance" "ansible_control" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"


  subnet_id     = aws_subnet.main_subnet.id

  key_name      = "aws_permision_file_work"

  # usa a vpc/subnet default da região
  associate_public_ip_address = true
  
  # security group
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
  
  # user data para instalar ansible
  user_data = <<-eof
    #!/bin/bash
    yum update -y
    amazon-linux-extras install ansible2 -y

    # setup ansible user (from script)
    ${file("${path.module}/../../scripts/ansible-control/setup-user.sh")}
  eof
  
  tags = {
    name        = "ansible-control-${var.environment}"
    environment = var.environment
    managedby   = "terraform"
    role        = "ansible-control"
  }
}

resource "aws_security_group" "ansible_sg" {
  name        = "ansible-control-sg-${var.environment}"
  description = "Security group for Ansible control node"
  vpc_id = aws_vpc.main_vpc.id
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
