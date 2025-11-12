resource "local_file" "ansible_playbook" {
  content = templatefile("${path.module}/../../template_files/ansible_machine/setup_logger.yml.tpl", {})

  filename             = "${path.module}/../../ansible-playbooks/setup_logger.yml"
  file_permission      = "0644"
  directory_permission = "0755"
}

resource "null_resource" "copy_ansible_files" {
  triggers = {
    ansible_ip        = aws_instance.ansible_control.public_ip
    inventory_content = local_file.ansible_inventory.content
    playbook_content  = local_file.ansible_playbook.content
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "========================================"
      echo "Waiting 60 seconds for Ansible control node to be ready..."
      echo "========================================"
      if [ -f ~/.ssh/aws_permision_file_work.pem ]; then
            echo "Key file exists"
       else
            echo "Key file NOT found"
      fi
      sleep 60
      echo "Step 1: Creating .ssh directory on Ansible control node..."
      ssh -o StrictHostKeyChecking=no \
          -i ~/.ssh/aws_permision_file_work.pem \
          ec2-user@${aws_instance.ansible_control.public_ip} \
          "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
      
      echo "Step 2: Copying SSH key to Ansible control node..."
      scp -o StrictHostKeyChecking=no \
          -i ~/.ssh/aws_permision_file_work.pem \
          ~/.ssh/aws_permision_file_work.pem \
          ec2-user@${aws_instance.ansible_control.public_ip}:~/.ssh/
      
      echo "Step 3: Setting correct permissions on the key..."
      ssh -o StrictHostKeyChecking=no \
          -i ~/.ssh/aws_permision_file_work.pem \
          ec2-user@${aws_instance.ansible_control.public_ip} \
          "chmod 400 ~/.ssh/aws_permision_file_work.pem"
      
      echo "Step 4: Adding runner to known_hosts..."
      ssh -o StrictHostKeyChecking=no \
          -i ~/.ssh/aws_permision_file_work.pem \
          ec2-user@${aws_instance.ansible_control.public_ip} \
          "ssh-keyscan -H ${aws_instance.machine_runner.private_ip} >> ~/.ssh/known_hosts 2>/dev/null"
      
      echo "Step 5: Copying inventory file..."
      scp -o StrictHostKeyChecking=no \
          -i ~/.ssh/aws_permision_file_work.pem \
          ${path.module}/../../ansible-playbooks/inventory.ini \
          ec2-user@${aws_instance.ansible_control.public_ip}:~/
      
      echo "Step 6: Copying playbook..."
      scp -o StrictHostKeyChecking=no \
          -i ~/.ssh/aws_permision_file_work.pem \
          ${path.module}/../../ansible-playbooks/setup_logger.yml \
          ec2-user@${aws_instance.ansible_control.public_ip}:~/
      
      echo "Step 7: Copying testing script..."
      scp -o StrictHostKeyChecking=no \
          -i ~/.ssh/aws_permision_file_work.pem \
          ${path.module}/../../scripts/ansible-control/testing_script_file.sh \
          ec2-user@${aws_instance.ansible_control.public_ip}:~/testing_script_file.sh
      
      echo "Step 8: Running Ansible playbook..."
      ssh -o StrictHostKeyChecking=no \
          -i ~/.ssh/aws_permision_file_work.pem \
          ec2-user@${aws_instance.ansible_control.public_ip} \
          "ansible-playbook -i inventory.ini setup_logger.yml"
      
      echo "========================================"
      echo "Ansible setup completed successfully!"
      echo "========================================"
    EOT
  }

  depends_on = [
    local_file.ansible_inventory,
    local_file.ansible_playbook,
    aws_instance.machine_runner,
    aws_instance.ansible_control
  ]
}
