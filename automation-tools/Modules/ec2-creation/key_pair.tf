# SSH Key Pair - Using existing key pair
data "aws_key_pair" "runner" {
  key_name = "aws_permision_file_work"
}

