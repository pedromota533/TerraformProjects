# Ansible Control Node

## Visão Geral

O **Ansible Control Node** é a máquina principal que executa o Ansible e gere outras máquinas (managed nodes). É a partir desta máquina que os playbooks e comandos Ansible são executados.

## Configuração

### Recurso Terraform.
-

 **Ficheiro**: `terraform/DEV/ansible-machine.tf`
- **Security Group**: `aws_security_group.ansible_sg`

## User Data (Inicialização)
Quando a instância é criada, o seguinte script é executado automaticamente:
```bash
#!/bin/bash
yum update -y
amazon-linux-extras install ansible2 -y

# Setup ansible user (from script)
${file("${path.module}/../../scripts/ansible-control/setup-user.sh")}
```

### Script de Setup (`scripts/ansible-control/setup-user.sh`)

O script modular que configura o user ansible:

```bash
#!/bin/bash
# Setup user for Ansible Control Node

# Create ansible user
useradd -m -s /bin/bash ansible

# Setup SSH access for ansible user
mkdir -p /home/ansible/.ssh
chmod 700 /home/ansible/.ssh

# Copy authorized_keys from ec2-user (who gets the key from EC2 key pair)
cp /home/ec2-user/.ssh/authorized_keys /home/ansible/.ssh/authorized_keys
chmod 600 /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible/.ssh

# Sudo apenas para comandos Ansible
echo "ansible ALL=(ALL) NOPASSWD: /usr/bin/ansible, /usr/bin/ansible-playbook, /usr/bin/ansible-pull, /usr/bin/ansible-galaxy, /usr/bin/ansible-vault" >> /etc/sudoers.d/ansible

chmod 0440 /etc/sudoers.d/ansible
```

## Security Group (ansible_sg)
### Regras de Ingress (Entrada)
- **SSH (porta 22)**:
  - Origem: Teu IP (`var.my_ip`)
  - Descrição: "SSH access from Pedros IP"

### Regras de Egress (Saída)
- **Todo o tráfego**: Permitido para qualquer destino (`0.0.0.0/0`)

## Outputs
Após o deployment, os seguintes valores são disponibilizados:
- **`ansible_instance_id`**: ID da instância EC2
- **`ansible_public_ip`**: IP público da máquina
- **`ansible_private_ip`**: IP privado da máquina

### Como ver os outputs:
```bash
terraform output
terraform output ansible_public_ip
```

## Como conectar
```bash
# SSH como ec2-user (default)
ssh ec2-user@<ansible_public_ip>
# SSH como user ansible (recomendado)
ssh ansible@<ansible_public_ip>
```
**Nota**: Root SSH está **sempre desativado** (não é possível fazer `ssh root@...`)