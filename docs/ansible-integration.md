# Ansible Integration

## Visão Geral

Este documento descreve como o Terraform integra com o Ansible para automatizar a configuração das instâncias EC2. A integração é feita através de dois ficheiros principais:
- **`ansible-integration.tf`**: Gera o inventory do Ansible
- **`ansible-tasks.tf`**: Copia ficheiros e executa playbooks Ansible

## Ficheiro: ansible-integration.tf

**Localização**: `terraform/DEV/ansible-integration.tf`

### 1. Geração do Ansible Inventory

**Recurso**: `local_file.ansible_inventory`

**O que faz**:
- Usa o template `inventory.tpl` para gerar `ansible-playbooks/inventory.ini`
- Injeta os IPs privados das instâncias EC2 automaticamente
- Garante que as instâncias existem antes de criar o inventory

#### Template Usado

**Ficheiro**: `template_files/ansible_machine/inventory.tpl`

```ini
[runners]
runner ansible_host=${runner_private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws_permision_file_work.pem

[ansible_control]
ansible ansible_host=${ansible_private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws_permision_file_work.pem

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

**Variáveis substituídas**:
- `${runner_private_ip}`: IP privado da Runner Machine
- `${ansible_private_ip}`: IP privado do Ansible Control Node

#### Inventory Gerado (exemplo)

```ini
[runners]
runner ansible_host=10.0.0.5 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws_permision_file_work.pem

[ansible_control]
ansible ansible_host=10.0.0.4 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws_permision_file_work.pem

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

---

### 2. Output

**Output**: `ansible_inventory_location` - Mostra o caminho completo para o inventory gerado

---

## Ficheiro: ansible-tasks.tf

**Localização**: `terraform/DEV/ansible-tasks.tf`

### 1. Geração do Ansible Playbook

**Recurso**: `local_file.ansible_playbook`

**O que faz**:
- Gera `ansible-playbooks/setup_logger.yml` a partir do template
- Playbook de teste que configura um logger com systemd timer

---

### 2. Execução Automatizada via Terraform

**Recurso**: `null_resource.copy_ansible_files`

Este é o coração da integração Terraform-Ansible. O provisioner é re-executado quando:
- O IP do Ansible Control muda
- O conteúdo do inventory muda
- O conteúdo do playbook muda

### 3. Passos de Configuração

O provisioner executa automaticamente:

1. **Aguarda 60 segundos** - Para a instância estar completamente pronta
2. **Cria diretório .ssh** - No Ansible Control Node
3. **Copia SSH key** - Para permitir conexão ao Runner
4. **Configura permissões** - Define permissões corretas na key (400)
5. **Adiciona Runner aos known_hosts** - Evita prompts de confirmação SSH
6. **Copia inventory.ini** - Para o Ansible Control
7. **Copia playbook** - Para o Ansible Control
8. **Copia script de teste** - Para ser usado no Runner
9. **Executa Ansible Playbook** - Configura o Runner Machine automaticamente

O provisioner só executa depois que todos os recursos estão criados (inventory, playbook, ambas as instâncias).

---

## Fluxo Completo de Integração

```
1. Terraform cria instâncias EC2
   ├── Ansible Control Node
   └── Runner Machine

2. Terraform gera ficheiros Ansible
   ├── inventory.ini (com IPs privados)
   └── setup_logger.yml

3. Terraform copia ficheiros para Ansible Control
   ├── SSH key
   ├── inventory.ini
   ├── setup_logger.yml
   └── testing_script_file.sh

4. Terraform executa Ansible Playbook
   └── Ansible configura Runner Machine automaticamente

5. Setup completo!
```

---

## Vantagens desta Abordagem

### Automação Completa
- ✅ Uma execução de `terraform apply` faz tudo
- ✅ Não é necessário SSH manual
- ✅ Configuração consistente e repetível

### Gestão de Configuração
- ✅ IPs privados injetados automaticamente
- ✅ Inventory sempre atualizado
- ✅ Templates reutilizáveis

### Infraestrutura como Código
- ✅ Todo o setup versionado no Git
- ✅ Fácil de replicar em diferentes ambientes
- ✅ Documentação automática via código

---

## Comandos Úteis

### Ver o inventory gerado
```bash
cat ansible-playbooks/inventory.ini
```

### Verificar se o playbook foi copiado
```bash
ssh -i ~/.ssh/aws_permision_file_work.pem ec2-user@<ansible_public_ip> "ls -la ~/"
```

### Executar playbook manualmente
```bash
ssh -i ~/.ssh/aws_permision_file_work.pem ec2-user@<ansible_public_ip>
ansible-playbook -i inventory.ini setup_logger.yml
```

### Verificar logs de execução
```bash
# Ver logs do terraform apply
terraform apply 2>&1 | tee terraform-apply.log

# Ver logs no Ansible Control Node
ssh ... "cat /var/log/ansible-setup.log"
```

---

## Troubleshooting

### "Permission denied" ao copiar SSH key
- ✅ Verifica que o ficheiro `~/.ssh/aws_permision_file_work.pem` existe localmente
- ✅ Verifica permissões: `chmod 400 ~/.ssh/aws_permision_file_work.pem`

### "Connection refused" ao SSH
- ✅ Aguarda mais tempo (aumenta o sleep de 60s para 90s)
- ✅ Verifica Security Group do Ansible Control Node
- ✅ Verifica que o IP público está correto

### Ansible não consegue conectar ao Runner
- ✅ Verifica que o IP **privado** está no inventory
- ✅ Verifica que a SSH key foi copiada corretamente
- ✅ Verifica que o known_hosts foi atualizado
- ✅ Verifica Security Group do Runner (deve permitir tráfego do Ansible Control)

### Playbook falha com "host not found"
- ✅ Verifica o inventory.ini no Ansible Control Node
- ✅ Confirma que os IPs privados estão corretos
- ✅ Testa conectividade: `ansible runners -i inventory.ini -m ping`

---

## Referências

- [Terraform local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file)
- [Terraform null_resource](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)
- [Terraform templatefile function](https://www.terraform.io/language/functions/templatefile)
- [Ansible Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)
- [Ansible Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html)
