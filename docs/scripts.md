# Scripts Documentation

## Visão Geral

Este documento descreve todos os scripts utilizados no projeto para configuração e automação. Os scripts estão organizados por tipo de máquina e propósito.

## Estrutura dos Scripts

```
scripts/
├── ansible-control/
│   ├── setup-user.sh            # Configuração do user ansible (sudo restrito)
│   └── testing_script_file.sh   # Script de teste para logging
├── runner/
│   └── setup-user.sh            # Configuração do user ansible (sudo completo)
└── terraform_execution.sh       # Script de execução do Terraform
```

---

## Scripts do Ansible Control Node

### 1. setup-user.sh

**Localização**: `scripts/ansible-control/setup-user.sh`

**Propósito**: Configurar o user `ansible` no Ansible Control Node com permissões sudo **restritas**.

#### O que faz

1. **Criar user ansible** com home directory e bash shell
2. **Configurar SSH access** - Cria `.ssh` e copia `authorized_keys` do ec2-user
3. **Configurar sudo restrito** - User `ansible` só pode executar comandos Ansible com sudo (sem password)

#### Comandos Ansible Permitidos com Sudo
- ansible, ansible-playbook, ansible-pull, ansible-galaxy, ansible-vault

#### Usado Por
`terraform/DEV/ansible-machine.tf` via `file()` function no `user_data`

---

### 2. testing_script_file.sh

**Localização**: `scripts/ansible-control/testing_script_file.sh`

**Propósito**: Script de teste para logging usado pelo Ansible playbook.

#### O que faz

Escreve mensagens de log em `/var/log/ansible-setup.log`:
- Header de setup
- Timestamp
- Variável de ambiente (se definida)
- Mensagem de conclusão

#### Usado Por
- Copiado via `ansible-tasks.tf` para o Ansible Control
- Depois copiado para o Runner via Ansible playbook
- Executado no Runner a cada 5 segundos via systemd timer

---

## Scripts do Runner Machine

### 1. setup-user.sh

**Localização**: `scripts/runner/setup-user.sh`

**Propósito**: Configurar o user `ansible` no Runner Machine com permissões sudo **completas**.

#### O que faz

1. **Criar user ansible** com home directory e bash shell
2. **Configurar sudo completo** - User `ansible` pode executar **QUALQUER** comando com sudo (sem password)

Necessário para permitir que o Ansible gerencie completamente a máquina.

#### Diferença do Ansible Control

| Aspecto | Ansible Control | Runner Machine |
|---------|----------------|----------------|
| **Sudo** | Restrito (apenas comandos Ansible) | Completo (todos os comandos) |
| **SSH Setup** | Copia authorized_keys do ec2-user | Não configurado (feito pelo Ansible) |
| **Razão** | Segurança - limita privilégios | Gestão - permite configuração total |

#### Usado Por
`terraform/DEV/runner-machine.tf` via `file()` function no `user_data`

---

## Script de Execução do Terraform

### terraform_execution.sh

**Localização**: `scripts/terraform_execution.sh`

**Propósito**: Script wrapper para executar Terraform com validações e controle de fluxo.

#### Parâmetros

```bash
./terraform_execution.sh \
  <AWS_ACCESS_KEY_ID> \
  <AWS_SECRET_ACCESS_KEY> \
  <DEPLOY_TARGET> \
  <DEPLOY_PLATFORM> \
  <TERRAFORM_ACTION> \
  <DESTROY_ACTION>
```

| Parâmetro | Descrição | Valores |
|-----------|-----------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | String |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | String |
| `DEPLOY_TARGET` | Ambiente (DEV/PROD) | `DEV`, `PROD` |
| `DEPLOY_PLATFORM` | Plataforma cloud | `AWS`, `Azure` |
| `TERRAFORM_ACTION` | Ação do Terraform | `plan`, `apply` |
| `DESTROY_ACTION` | Destruir antes de aplicar? | `yes`, `no` |

#### Exemplo de Uso

```bash
# Executar plan em DEV
./terraform_execution.sh \
  "AKIAIOSFODNN7EXAMPLE" \
  "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" \
  "DEV" \
  "AWS" \
  "plan" \
  "no"

# Executar apply em DEV (sem destruir)
./terraform_execution.sh \
  "AKIAIOSFODNN7EXAMPLE" \
  "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" \
  "DEV" \
  "AWS" \
  "apply" \
  "no"

# Destruir e recriar em DEV
./terraform_execution.sh \
  "AKIAIOSFODNN7EXAMPLE" \
  "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" \
  "DEV" \
  "AWS" \
  "apply" \
  "yes"
```

#### Funções do Script

##### 1. validate_required_params()
Valida que todos os parâmetros obrigatórios foram fornecidos.

##### 2. validate_terraform_action()
```bash
if [[ ! "$TERRAFORM_ACTION" =~ ^(apply|plan)$ ]]; then
  echo "ERROR: TERRAFORM_ACTION must be 'apply' or 'plan'"
  exit 1
fi
```

##### 3. validate_destroy_action()
```bash
if [[ ! "$DESTROY_ACTION" =~ ^(yes|no)$ ]]; then
  echo "ERROR: DESTROY_ACTION must be 'yes' or 'no'"
  exit 1
fi
```

##### 4. setup_aws_environment()
```bash
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION="${AWS_REGION:-eu-west-1}"
```
Configura variáveis de ambiente AWS.

##### 5. validate_terraform_directory()
Verifica que o diretório Terraform existe e contém `main.tf`.

##### 6. run_terraform_destroy()
```bash
terraform destroy -auto-approve
```

##### 7. run_terraform_init()
```bash
terraform init
```

##### 8. run_terraform_validate()
```bash
terraform validate
```

##### 9. run_terraform_plan()
```bash
terraform plan -out=tfplan
```

##### 10. run_terraform_apply()
```bash
terraform apply -auto-approve tfplan
```

#### Fluxo de Execução

```
1. Validar parâmetros
2. Setup AWS environment
3. Validar diretório Terraform
4. [Se DESTROY_ACTION=yes] Executar destroy
5. Executar init
6. Executar validate
7. Executar plan
8. [Se TERRAFORM_ACTION=apply] Executar apply
```

#### Características de Segurança

- ✅ Validação rigorosa de inputs
- ✅ Exit em caso de erro (`set -e`)
- ✅ Tratamento de erros em pipelines (`set -o pipefail`)
- ✅ Mensagens de erro claras
- ⚠️ Credenciais AWS via parâmetros (não ideal para produção)

**Nota**: Para melhorias sugeridas, consultar `todo.md` na raiz do projeto.

---

## Boas Práticas para Scripts

### Segurança
1. ✅ Sempre usar `#!/bin/bash` no início
2. ✅ Usar `set -e` para sair em caso de erro
3. ✅ Validar inputs antes de usar
4. ✅ Usar permissões apropriadas (0440 para sudoers, 0755 para executáveis)
5. ✅ Não colocar credenciais hardcoded nos scripts

### Manutenibilidade
1. ✅ Comentar o código
2. ✅ Usar funções para organizar lógica
3. ✅ Mensagens de erro claras
4. ✅ Logging apropriado
5. ✅ Variáveis com nomes descritivos

### Testabilidade
1. ✅ Testar scripts localmente antes de usar no Terraform
2. ✅ Adicionar dry-run mode quando possível
3. ✅ Verificar exit codes
4. ✅ Usar shellcheck para validar sintaxe

---

## Como Testar os Scripts

### setup-user.sh (Ansible Control)
```bash
# Num container ou VM de teste
docker run -it amazonlinux:2 bash
yum install -y sudo

# Copiar e executar o script
bash setup-user.sh

# Verificar
cat /etc/sudoers.d/ansible
ls -la /home/ansible/.ssh
```

### setup-user.sh (Runner)
```bash
# Similar ao anterior
docker run -it amazonlinux:2 bash
yum install -y sudo

bash setup-user.sh

# Verificar
cat /etc/sudoers.d/ansible
id ansible
```

### terraform_execution.sh
```bash
# Testar validações
./terraform_execution.sh

# Testar com parâmetros inválidos
./terraform_execution.sh "key" "secret" "DEV" "AWS" "invalid" "no"

# Testar plan
./terraform_execution.sh "key" "secret" "DEV" "AWS" "plan" "no"
```

---

## Troubleshooting

### "Permission denied" ao executar script
```bash
chmod +x scripts/ansible-control/setup-user.sh
chmod +x scripts/runner/setup-user.sh
chmod +x scripts/terraform_execution.sh
```

### User ansible não foi criado
```bash
# Ver logs do user_data
sudo cat /var/log/cloud-init-output.log

# Verificar se o script foi executado
sudo grep -i "ansible" /var/log/cloud-init-output.log
```

### Sudoers não funciona
```bash
# Verificar sintaxe
sudo visudo -cf /etc/sudoers.d/ansible

# Verificar permissões
ls -la /etc/sudoers.d/ansible
# Deve ser: -r--r----- (0440)
```

---

## Referências

- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide/Practices)
- [ShellCheck - Linter para Shell Scripts](https://www.shellcheck.net/)
- [AWS EC2 User Data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [Sudoers Manual](https://www.sudo.ws/docs/man/sudoers.man/)
