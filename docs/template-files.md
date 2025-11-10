# Template Files Documentation

## Visão Geral

Este documento descreve os ficheiros template utilizados no projeto. Templates permitem criar ficheiros dinâmicos onde variáveis são substituídas por valores reais durante a execução do Terraform.

## Estrutura dos Templates

```
template_files/
└── ansible_machine/
    ├── inventory.tpl           # Template do inventory Ansible
    └── setup_logger.yml.tpl    # Template do playbook Ansible
```

---

## Template: inventory.tpl

**Localização**: `template_files/ansible_machine/inventory.tpl`

**Propósito**: Gerar dinamicamente o ficheiro inventory do Ansible com os IPs privados das instâncias EC2.

### Conteúdo do Template

```ini
[runners]
runner ansible_host=${runner_private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws_permision_file_work.pem

[ansible_control]
ansible ansible_host=${ansible_private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws_permision_file_work.pem

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

### Variáveis do Template

| Variável | Tipo | Descrição | Exemplo |
|----------|------|-----------|---------|
| `${runner_private_ip}` | String | IP privado da Runner Machine | `10.0.0.5` |
| `${ansible_private_ip}` | String | IP privado do Ansible Control Node | `10.0.0.4` |

### Como é Usado

**Ficheiro**: `terraform/DEV/ansible-integration.tf`

O Terraform usa `templatefile()` para substituir as variáveis pelos IPs reais das instâncias e gera o ficheiro `ansible-playbooks/inventory.ini`.

### Ficheiro Gerado (inventory.ini)

**Localização**: `ansible-playbooks/inventory.ini`

**Exemplo com valores reais**:

```ini
[runners]
runner ansible_host=10.0.0.5 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws_permision_file_work.pem

[ansible_control]
ansible ansible_host=10.0.0.4 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/aws_permision_file_work.pem

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

### Explicação dos Grupos

#### [runners]
Grupo contendo as máquinas gerenciadas (managed nodes).

**Parâmetros**:
- `runner`: Nome do host no inventory
- `ansible_host=10.0.0.5`: IP privado para conexão
- `ansible_user=ec2-user`: User para SSH
- `ansible_ssh_private_key_file`: Caminho para a chave SSH

#### [ansible_control]
Grupo contendo o Ansible Control Node (para auto-gestão).

**Parâmetros**: Similares ao grupo `runners`.

#### [all:vars]
Variáveis aplicadas a todos os hosts.

**Parâmetros**:
- `ansible_python_interpreter=/usr/bin/python3`: Define o interpretador Python a usar

### Por que IPs Privados?

✅ **Vantagens**:
- Comunicação mais rápida (rede interna)
- Mais seguro (não exposto à Internet)
- Sem custos de transferência de dados
- Funciona mesmo que IPs públicos mudem

❌ **Requisitos**:
- Ambas as máquinas devem estar na mesma VPC/Subnet ou com conectividade configurada
- Security Groups devem permitir comunicação entre elas

---

## Template: setup_logger.yml.tpl

**Localização**: `template_files/ansible_machine/setup_logger.yml.tpl`

**Propósito**: Gerar o playbook Ansible que configura um logger com systemd timer no Runner Machine.

### Conteúdo do Template

```yaml
---
- name: Setup timestamp logger with systemd timer
  hosts: runners
  become: yes

  tasks:
    - name: Copy logging script from Ansible control node
      copy:
        src: ~/testing_script_file.sh
        dest: /usr/local/bin/log_with_timestamp.sh
        mode: '0755'
        owner: root
        group: root

    - name: Create log file with proper permissions
      file:
        path: /var/log/timestamp_log.log
        state: touch
        mode: '0644'
        owner: root
        group: root

    - name: Create systemd service
      copy:
        dest: /etc/systemd/system/timestamp-logger.service
        content: |
          [Unit]
          Description=Timestamp Logger Service

          [Service]
          Type=oneshot
          ExecStart=/usr/local/bin/log_with_timestamp.sh

          [Install]
          WantedBy=multi-user.target
        mode: '0644'

    - name: Create systemd timer
      copy:
        dest: /etc/systemd/system/timestamp-logger.timer
        content: |
          [Unit]
          Description=Run timestamp logger every 5 seconds

          [Timer]
          OnBootSec=5sec
          OnUnitActiveSec=5sec

          [Install]
          WantedBy=timers.target
        mode: '0644'

    - name: Reload systemd daemon
      systemd:
        daemon_reload: yes

    - name: Enable and start the timer
      systemd:
        name: timestamp-logger.timer
        enabled: yes
        state: started
```

### Variáveis do Template

Este template **não tem variáveis** (o segundo parâmetro do `templatefile()` está vazio: `{}`).

### Como é Usado

**Ficheiro**: `terraform/DEV/ansible-tasks.tf`

O Terraform gera `ansible-playbooks/setup_logger.yml` a partir deste template (sem substituições de variáveis).

### Ficheiro Gerado (setup_logger.yml)

**Localização**: `ansible-playbooks/setup_logger.yml`

O ficheiro gerado é **idêntico** ao template (sem substituições).

### O que o Playbook Faz

O playbook configura um logger de teste no Runner Machine:

1. **Copia o script de logging** - Do Ansible Control para `/usr/local/bin/log_with_timestamp.sh`
2. **Cria ficheiro de log** - `/var/log/timestamp_log.log`
3. **Cria systemd service** - Define o service que executa o script (Type=oneshot)
4. **Cria systemd timer** - Configura execução a cada 5 segundos
5. **Recarrega systemd** - Para reconhecer os novos service/timer
6. **Ativa e inicia o timer** - Timer começa a funcionar imediatamente e no boot

### Resultado Final

Após executar o playbook:
1. ✅ Script de logging instalado em `/usr/local/bin/log_with_timestamp.sh`
2. ✅ Systemd service criado
3. ✅ Systemd timer criado e ativo
4. ✅ Script executado a cada 5 segundos
5. ✅ Logs escritos em `/var/log/timestamp_log.log`

### Verificar o Logger no Runner

```bash
# Ver o timer ativo
systemctl list-timers

# Ver o status do timer
systemctl status timestamp-logger.timer

# Ver o status do service
systemctl status timestamp-logger.service

# Ver os logs
cat /var/log/timestamp_log.log

# Seguir os logs em tempo real
tail -f /var/log/timestamp_log.log
```

---

## Função templatefile() do Terraform

**Sintaxe**: `templatefile(path, vars)`

- `path`: Caminho para o ficheiro template
- `vars`: Map de variáveis a substituir no template

**Sintaxe de variáveis no template**: `${variable_name}`

---

## Boas Práticas para Templates

### Organização
1. ✅ Agrupar templates por tipo (ansible, scripts, configs)
2. ✅ Usar extensão `.tpl` para identificar templates
3. ✅ Nomear templates de forma descritiva
4. ✅ Documentar variáveis esperadas

### Segurança
1. ✅ Nunca colocar credenciais hardcoded em templates
2. ✅ Validar inputs antes de passar para templates
3. ✅ Usar variáveis Terraform sensíveis quando apropriado

### Manutenibilidade
1. ✅ Comentar templates complexos
2. ✅ Manter templates simples e focados
3. ✅ Versionar templates no Git
4. ✅ Testar templates antes de aplicar

---

## Adicionando Novos Templates

1. Criar ficheiro `.tpl` em `template_files/`
2. Definir variáveis com sintaxe `${variable_name}`
3. Usar `templatefile()` no Terraform com map de variáveis
4. Testar com `terraform plan` e `apply`

---

## Templates Avançados

Terraform templates suportam:

**Condicionais**: `%{ if condition } ... %{ else } ... %{ endif }`

**Loops**: `%{ for item in list } ... %{ endfor }`

Útil para criar configurações dinâmicas baseadas em listas ou condições.

---

## Troubleshooting

### "Invalid template interpolation value"
- Verifica que todas as variáveis no template foram fornecidas no map
- Verifica a sintaxe: `${variable_name}`

### "Error in function call"
- Verifica o caminho para o template
- Usa `path.module` para caminhos relativos corretos

### Template não substitui variáveis
- Verifica que estás a usar `templatefile()` e não `file()`
- Verifica a sintaxe das variáveis: `${var}` não `{{var}}`

### Ficheiro gerado está vazio
- Verifica permissões do template
- Verifica que o template existe
- Verifica logs do Terraform

---

## Referências

- [Terraform templatefile Function](https://www.terraform.io/language/functions/templatefile)
- [Terraform Template Syntax](https://www.terraform.io/language/expressions/strings#string-templates)
- [Ansible Inventory Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)
- [Ansible Playbooks Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html)
- [Systemd Timer Documentation](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
