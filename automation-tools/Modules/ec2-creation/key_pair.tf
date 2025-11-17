# SSH Key Pair - Create key pair from local public key
resource "aws_key_pair" "runner" {
  key_name   = "github-runner-key"
  public_key = file("~/.ssh/id_ed25519.pub")

  tags = {
    Name = "GitHub Runner Key"
  }
}

