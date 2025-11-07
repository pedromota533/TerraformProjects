resource "aws_instance" "machine_runner" {

    ami           = data.aws_ami.amazon_linux.id
    instance_type = "t2.micro"

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


}