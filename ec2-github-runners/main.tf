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

output "ami_info" {
  description = "AMI information used for instances"
  value = {
    id            = data.aws_ami.amazon_linux.id
    name          = data.aws_ami.amazon_linux.name
    description   = data.aws_ami.amazon_linux.description
    creation_date = data.aws_ami.amazon_linux.creation_date
  }
}
