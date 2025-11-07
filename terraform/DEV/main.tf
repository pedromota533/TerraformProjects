provider "aws" {
  region = var.aws_region
}

# Variável para a região (pode ser overridden)
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

# Variável para o ambiente
variable "environment" {
  description = "Environment name (dev/staging/production)"
  type        = string
  default     = "dev"
}

# Fetch da AMI mais recente do Amazon Linux 2
data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instância EC2
resource "aws_instance" "test" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  
  tags = {
    Name        = "FreeTier-Instance-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "ami_info" {
  description = "AMI information used for the instance"
  value = {
    id              = data.aws_ami.amazon_linux.id
    name            = data.aws_ami.amazon_linux.name
    description     = data.aws_ami.amazon_linux.description
    creation_date   = data.aws_ami.amazon_linux.creation_date
  }
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.test.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.test.public_ip
}

output "instance_state" {
  description = "State of the instance"
  value       = aws_instance.test.instance_state
}
