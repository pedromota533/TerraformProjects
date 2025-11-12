resource "local_file" "config_ini" {
  filename = "${path.module}/config.ini"

  content = <<-EOT
[runners]
# Individual IPs (one per line)
%{for idx, ip in local.runner_public_ips~}
${ip}
%{endfor~}
EOT

  file_permission = "0644"
}
