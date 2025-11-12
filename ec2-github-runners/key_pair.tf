# SSH Key Pair - Using existing key pair
data "aws_key_pair" "runner" {
  key_name = "aws_permision_file_work"
}

output "key_pair_name" {
  description = "SSH key pair name"
  value       = data.aws_key_pair.runner.key_name
}
