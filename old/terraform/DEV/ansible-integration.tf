resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../../template_files/ansible_machine/inventory.tpl", {
    runner_private_ip  = aws_instance.machine_runner.private_ip
    ansible_private_ip = aws_instance.ansible_control.private_ip
  })
  
  filename             = "${path.module}/../../ansible-playbooks/inventory.ini"
  file_permission      = "0644"
  directory_permission = "0755"

  depends_on = [
    aws_instance.machine_runner,
    aws_instance.ansible_control
  ]
}

output "ansible_inventory_location" {
  description = "Location of generated Ansible inventory"
  value       = abspath("${path.module}/../../ansible-playbooks/inventory.ini")
}