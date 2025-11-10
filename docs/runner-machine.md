# Runner Machine (Managed Node)

## Visão Geral

A **Runner Machine** é uma máquina gerenciada (managed node) que será controlada pelo Ansible Control Node. Esta máquina serve como alvo para executar tarefas automatizadas via Ansible.

## Configuração

### Recurso Terraform
- **Ficheiro**: `terraform/DEV/runner-machine.tf`
- **Recurso**: `aws_instance.machine_runner`

### Especificações da Instância
- **AMI**: Amazon Linux 2 (latest) - Lightweight e RHEL-based
- **Instance Type**: `t2.micro` (free tier eligible)
- **Public IP**: Ativado
- **Security Group**: `aws_security_group.runner_sg`

### Status Atual
- ✅ **User data**: Configurado
- ✅ **Tags**: Configuradas
- ✅ **Security Group**: Criado (`runner_sg`)
- ✅ **Outputs**: Configurados (`runner_private_ip`, `runner_instance_id`)

## User Data (Inicialização)

Quando a instância é criada, o seguinte script é executado automaticamente:

```bash
#!/bin/bash
yum update -y

# Setup ansible user (from script)
${file("${path.module}/../../scripts/runner/setup-user.sh")}
```

### Script de Setup (`scripts/runner/setup-user.sh`)

O script modular que configura o user ansible:

```bash
#!/bin/bash
# Setup user for Runner Machine (Managed Node)

# Create ansible user
useradd -m -s /bin/bash ansible

# Sudo completo (sem password)
echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible

chmod 0440 /etc/sudoers.d/ansible
```

### O que faz:
1. **Atualiza o sistema**: `yum update -y`
2. **Cria user ansible**: User dedicado para gestão via Ansible
3. **Sudo COMPLETO**: O user `ansible` tem sudo **COMPLETO** para executar qualquer tarefa
4. **Sem Root SSH**: Root SSH está **sempre desativado** (configuração segura por defeito)

## Security Group (runner_sg)

### Regras de Ingress (Entrada)
- **Todo o tráfego do Ansible Control Node**:
  - Protocolo: `-1` (todos)
  - Origem: `aws_security_group.ansible_sg.id`
  - Descrição: "All traffic from Ansible control node"
  - **Portas**: Todas (0 a 0)

**Importante**: O Runner **apenas** aceita tráfego do Ansible Control Node, não do teu IP diretamente. Isto é mais seguro pois o Runner não está exposto à Internet diretamente.

### Regras de Egress (Saída)
- **Todo o tráfego**: Permitido para qualquer destino (`0.0.0.0/0`)

### Tags
- `Name`: `runner-sg-${var.environment}`
- `Environment`: Valor da variável `environment`
- `ManagedBy`: `Terraform`
- `Role`: `Ansible-Managed`

## Como o Ansible se Conecta

O Ansible Control Node conecta-se a esta máquina via SSH:

1. **Via user ansible**: O Ansible usa o user `ansible` para se conectar
2. **Autenticação**: Pode ser via SSH key ou password
3. **Execução de tarefas**: O user `ansible` tem privilégios sudo para executar tarefas

### Exemplo de Inventory Ansible

```ini
[runners]
runner1 ansible_host=<runner_public_ip> ansible_user=ansible

[runners:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

## Outputs

Após o deployment, os seguintes valores são disponibilizados:

- **`runner_instance_id`**: ID da instância EC2
- **`runner_private_ip`**: IP privado da máquina (usado pelo Ansible)

**Nota**: Não há output para IP público, embora a instância tenha um. O IP privado é usado para comunicação com o Ansible Control Node.

### Como ver os outputs:
```bash
terraform output
terraform output runner_private_ip
```

## Como Conectar

```bash
# SSH como ec2-user (default)
ssh ec2-user@<runner_public_ip>

# SSH como user ansible (recomendado para gestão via Ansible)
ssh ansible@<runner_public_ip>
```

**Nota**: Root SSH está **sempre desativado** (não é possível fazer `ssh root@...`)

## Notas de Segurança

- ✅ Root SSH está **sempre desativado** (configuração segura)
- ✅ O runner **apenas** aceita conexões do Ansible Control Node (não do teu IP diretamente)
- ✅ Comunicação via IPs privados dentro da VPC (mais seguro)
- ✅ O user `ansible` tem sudo **COMPLETO** para permitir gestão completa via Ansible
- ✅ Scripts modulares em `scripts/runner/` para fácil manutenção
- ⚠️ User `ansible` tem privilégios elevados - protege bem as SSH keys!
- ℹ️ Para aceder ao Runner, conecta primeiro ao Ansible Control e depois salta para o Runner