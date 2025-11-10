[runners]
runner ansible_host=${runner_private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws_permision_file_work.pem

[ansible_control]
ansible ansible_host=${ansible_private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws_permision_file_work.pem

[all:vars]
ansible_python_interpreter=/usr/bin/python3