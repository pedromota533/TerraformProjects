# Ansible Control Node

## Visão Geral

O **Ansible Control Node** é a máquina principal que executa o Ansible e gere outras máquinas (managed nodes). É a partir desta máquina que os playbooks e comandos Ansible são executados.

## Configuração

### Recurso Terraform
- **Ficheiro**: `terraform/DEV/ansible-machine.tf`
- **Recurso**: `aws_instance.ansible_control`

### Especificações da Instância
- **AMI**: Amazon Linux 2 (latest)
- **Instance Type**: `t2.micro` (free tier eligible)
- **Public IP**: Ativado
- **Security Group**: `aws_security_group.ansible_sg`

### Tags
- `Name`: `Ansible-Control-${var.environment}`
- `Environment`: Valor da variável `environment` (DEV/PROD)
- `ManagedBy`: `Terraform`
- `Role`: `Ansible-Control`

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

# Sudo apenas para comandos Ansible
echo "ansible ALL=(ALL) NOPASSWD: /usr/bin/ansible, /usr/bin/ansible-playbook, /usr/bin/ansible-pull, /usr/bin/ansible-galaxy, /usr/bin/ansible-vault" >> /etc/sudoers.d/ansible

chmod 0440 /etc/sudoers.d/ansible
```

### O que faz:
1. **Atualiza o sistema**: `yum update -y`
2. **Instala Ansible 2**: `amazon-linux-extras install ansible2 -y`
3. **Cria user ansible**: User dedicado para operações Ansible
4. **Sudo RESTRITO**: O user `ansible` tem sudo **APENAS** para comandos Ansible:
   - `/usr/bin/ansible`
   - `/usr/bin/ansible-playbook`
   - `/usr/bin/ansible-pull`
   - `/usr/bin/ansible-galaxy`
   - `/usr/bin/ansible-vault`
5. **Sem Root SSH**: Root SSH está **sempre desativado** (configuração segura por defeito)

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

## Notas de Segurança

- ✅ Root SSH está **sempre desativado** (configuração segura)
- ✅ Apenas o teu IP pode aceder via SSH
- ✅ O user `ansible` tem sudo **RESTRITO** - apenas para comandos Ansible
- ✅ Scripts modulares em `scripts/ansible-control/` para fácil manutenção
- ⚠️ Para outros comandos sudo, usa o user `ec2-user` (tem sudo completo)