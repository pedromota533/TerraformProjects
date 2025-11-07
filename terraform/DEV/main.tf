provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name (DEV/QUA/PRD)"
  type        = string
  default     = "DEV"
}

variable "my_ip" {
  description = "My public IP address for SSH access"
  type        = string
  default     = "148.63.55.136/32"
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

# Output da AMI (útil para debug)
output "ami_info" {
  description = "AMI information used for instances"
  value = {
    id            = data.aws_ami.amazon_linux.id
    name          = data.aws_ami.amazon_linux.name
    description   = data.aws_ami.amazon_linux.description
    creation_date = data.aws_ami.amazon_linux.creation_date
  }
}