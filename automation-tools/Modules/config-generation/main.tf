# Ensure config directory exists
resource "null_resource" "create_config_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.root}/../config"
  }
}

resource "local_file" "config_ini" {
  depends_on = [null_resource.create_config_dir]

  filename = "${path.root}/../config/config.ini"

  content = <<-EOT
[runners]
# Individual IPs (one per line)
%{for idx, ip in var.runner_public_ips~}
${ip}
%{endfor~}

[runners:vars]
ansible_ssh_private_key_file=~/.ssh/${var.key_pair_name}.pem
ansible_user=${var.ansible_user}
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=${var.ansible_python_interpreter}

# GitHub Runner Configuration
github_repo_url=${var.github_repo_url}
github_runner_token=${var.github_runner_token}
github_runner_version=${var.github_runner_version}
github_runner_dir=${var.github_runner_dir}
github_runner_labels=${var.github_runner_labels}
remove_runner=${var.remove_runner}
EOT

  file_permission = "0644"
}
