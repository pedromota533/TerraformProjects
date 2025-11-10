# Visão Geral dos Ficheiros Terraform

## Estrutura do Projeto

```
AutomaticTask/
├── terraform/
│   └── DEV/
│       ├── terraform.tf             # Configuração do Terraform e providers
│       ├── main.tf                  # Provider AWS, variáveis e AMI data source
│       ├── sub_net_enviroment.tf    # VPC, Subnet, Internet Gateway, Route Tables
│       ├── ansible-machine.tf       # Ansible Control Node
│       ├── runner-machine.tf        # Runner/Managed Machine
│       ├── ansible-integration.tf   # Geração do inventory Ansible
│       └── ansible-tasks.tf         # Execução de playbooks Ansible
├── scripts/                         # Scripts modulares para configuração
│   ├── ansible-control/
│   │   ├── setup-user.sh            # Setup do user ansible (sudo restrito)
│   │   └── testing_script_file.sh   # Script de teste para logging
│   ├── runner/
│   │   └── setup-user.sh            # Setup do user ansible (sudo completo)
│   └── terraform_execution.sh       # Script de execução do Terraform
├── template_files/                  # Templates para geração dinâmica
│   └── ansible_machine/
│       ├── inventory.tpl            # Template do inventory Ansible
│       └── setup_logger.yml.tpl     # Template do playbook Ansible
├── ansible-playbooks/               # Playbooks Ansible gerados (não versionados)
│   ├── inventory.ini                # Gerado por Terraform
│   └── setup_logger.yml             # Gerado por Terraform
├── docs/                            # Documentação
└── README.md                        # Visão geral do projeto
```

## Ficheiros Terraform

### 1. `terraform.tf`

**Localização**: `terraform/DEV/terraform.tf`

**Propósito**: Define os requisitos e configuração do Terraform.

**Conteúdo**:
- **Versão do Terraform**: `>= 1.0`
- **Providers requeridos**:
  - AWS Provider: `~> 5.0` (hashicorp/aws)

**Código**:
```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

**Quando modificar**:
- Ao mudar de versão do Terraform
- Ao adicionar novos providers (Azure, GCP, etc.)
- Ao atualizar versões de providers

---

### 2. `main.tf`

**Localização**: `terraform/DEV/main.tf`

**Propósito**: Configuração principal do projeto - provider AWS, variáveis e data sources.

**Conteúdo**:

#### Provider AWS
```hcl
provider "aws" {
  region = var.aws_region
}
```
- Define a região AWS a usar (padrão: `eu-central-1`)

#### Variáveis

| Variável | Tipo | Padrão | Descrição |
|----------|------|--------|-----------|
| `aws_region` | string | `eu-central-1` | Região AWS onde os recursos serão criados |
| `environment` | string | `DEV` | Nome do ambiente (DEV/QUA/PRD) |
| `my_ip` | string | `148.63.55.136/32` | Teu IP público para acesso SSH |

**Importante**: Atualiza `my_ip` com o teu IP real!

#### Data Source - AMI Amazon Linux 2

```hcl
data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

**O que faz**:
- Busca automaticamente a AMI mais recente do Amazon Linux 2
- Filtros garantem que é HVM e x86_64
- Não precisas de hardcoded AMI IDs

#### Output - AMI Info

```hcl
output "ami_info" {
  description = "AMI information used for instances"
  value = {
    id            = data.aws_ami.amazon_linux.id
    name          = data.aws_ami.amazon_linux.name
    description   = data.aws_ami.amazon_linux.description
    creation_date = data.aws_ami.amazon_linux.creation_date
  }
}
```

**Útil para**: Debug e verificar qual AMI está a ser usada.

---

### 3. `ansible-machine.tf`

**Localização**: `terraform/DEV/ansible-machine.tf`

**Propósito**: Define o Ansible Control Node e respetivo Security Group.

**Recursos criados**:
1. **`aws_instance.ansible_control`**: Instância EC2 do Ansible Control Node
2. **`aws_security_group.ansible_sg`**: Security Group para o Ansible Control

**Outputs**:
- `ansible_instance_id`
- `ansible_public_ip`
- `ansible_private_ip`

**Documentação detalhada**: Ver [ansible-machine.md](./ansible-machine.md)

---

### 4. `runner-machine.tf`

**Localização**: `terraform/DEV/runner-machine.tf`

**Propósito**: Define a Runner/Managed Machine que será gerida pelo Ansible.

**Recursos criados**:
1. **`aws_security_group.runner_sg`**: Security Group para o Runner
2. **`aws_instance.machine_runner`**: Instância EC2 da Runner Machine

**Outputs**:
- `runner_private_ip`
- `runner_instance_id`

**Documentação detalhada**: Ver [runner-machine.md](./runner-machine.md)

---

### 5. `sub_net_enviroment.tf`

**Localização**: `terraform/DEV/sub_net_enviroment.tf`

**Propósito**: Define toda a infraestrutura de rede (VPC, Subnet, Internet Gateway, Route Tables).

**Recursos criados**:
1. **`aws_vpc.main_vpc`**: VPC principal (10.0.0.0/24)
2. **`aws_subnet.main_subnet`**: Subnet principal (10.0.0.0/24)
3. **`aws_internet_gateway.main_igw`**: Internet Gateway para acesso externo
4. **`aws_route_table.main_rt`**: Route Table com route para Internet
5. **`aws_route_table_association.main_rta`**: Associação da Route Table à Subnet

**Características**:
- ✅ VPC isolada para o projeto
- ✅ Subnet única para todas as instâncias
- ✅ Comunicação interna via IPs privados
- ✅ Acesso à Internet via Internet Gateway

**Documentação detalhada**: Ver [networking.md](./networking.md)

---

### 6. `ansible-integration.tf`

**Localização**: `terraform/DEV/ansible-integration.tf`

**Propósito**: Gerar dinamicamente o inventory do Ansible com os IPs das instâncias.

**Recursos criados**:
1. **`local_file.ansible_inventory`**: Gera `ansible-playbooks/inventory.ini` a partir do template

**Template usado**: `template_files/ansible_machine/inventory.tpl`

**Variáveis injetadas**:
- `runner_private_ip`: IP privado do Runner
- `ansible_private_ip`: IP privado do Ansible Control

**Output**:
- `ansible_inventory_location`: Caminho absoluto para o inventory gerado

**Documentação detalhada**: Ver [ansible-integration.md](./ansible-integration.md)

---

### 7. `ansible-tasks.tf`

**Localização**: `terraform/DEV/ansible-tasks.tf`

**Propósito**: Automatizar a cópia de ficheiros e execução de playbooks Ansible.

**Recursos criados**:
1. **`local_file.ansible_playbook`**: Gera `ansible-playbooks/setup_logger.yml` a partir do template
2. **`null_resource.copy_ansible_files`**: Executa provisioner para:
   - Copiar SSH key para o Ansible Control Node
   - Copiar inventory e playbooks
   - Executar playbooks Ansible automaticamente

**Template usado**: `template_files/ansible_machine/setup_logger.yml.tpl`

**Passos executados**:
1. Aguardar 60 segundos
2. Criar diretório `.ssh` no Ansible Control
3. Copiar SSH key
4. Adicionar Runner aos known_hosts
5. Copiar inventory.ini
6. Copiar playbook
7. Copiar script de teste
8. Executar playbook Ansible

**Documentação detalhada**: Ver [ansible-integration.md](./ansible-integration.md)

---

## Scripts de Configuração

Os scripts modulares em `scripts/` são usados pelos ficheiros Terraform para configurar os users nas instâncias EC2 e para automação.

### 1. `scripts/ansible-control/setup-user.sh`

**Propósito**: Configura o user `ansible` no Ansible Control Node com sudo **restrito** e SSH access.

**Principais funcionalidades**:
- Cria o user `ansible`
- Configura SSH access (copia authorized_keys do ec2-user)
- Configura sudo **apenas** para comandos Ansible (segurança)

**Usado por**: `ansible-machine.tf` via `file()` function

---

### 2. `scripts/ansible-control/testing_script_file.sh`

**Propósito**: Script de teste para logging usado pelo Ansible playbook.

**Principais funcionalidades**:
- Escreve mensagens de log com timestamp
- Usado para testar a integração Ansible
- Executado no Runner a cada 5 segundos via systemd timer

**Usado por**:
- Copiado via `ansible-tasks.tf`
- Executado no Runner via Ansible playbook

---

### 3. `scripts/runner/setup-user.sh`

**Propósito**: Configura o user `ansible` na Runner Machine com sudo **completo**.

**Principais funcionalidades**:
- Cria o user `ansible`
- Configura sudo **completo** para permitir gestão total via Ansible

**Usado por**: `runner-machine.tf` via `file()` function

---

### 4. `scripts/terraform_execution.sh`

**Propósito**: Script wrapper para executar Terraform com validações e controle de fluxo.

**Parâmetros**:
1. AWS_ACCESS_KEY_ID
2. AWS_SECRET_ACCESS_KEY
3. DEPLOY_TARGET (DEV/PROD)
4. DEPLOY_PLATFORM (AWS/Azure)
5. TERRAFORM_ACTION (plan/apply)
6. DESTROY_ACTION (yes/no)

**Principais funcionalidades**:
- Valida todos os parâmetros
- Configura ambiente AWS
- Executa Terraform com opções de destroy
- Tratamento de erros robusto

**Documentação detalhada**: Ver [scripts.md](./scripts.md)

---

### Vantagens dos Scripts Modulares

- ✅ **Manutenção fácil**: Alterar um script atualiza todas as instâncias
- ✅ **Reutilização**: Mesmo script para DEV e PROD
- ✅ **Versionamento**: Scripts no Git para histórico
- ✅ **Testável**: Podes testar scripts independentemente
- ✅ **Legibilidade**: Código Terraform mais limpo

---

## Template Files

Os templates em `template_files/` são usados para gerar ficheiros dinâmicos com valores substituídos pelo Terraform.

### 1. `template_files/ansible_machine/inventory.tpl`

**Propósito**: Template para gerar o inventory do Ansible com IPs dinâmicos.

**Variáveis substituídas**:
- `${runner_private_ip}`: IP privado da Runner Machine
- `${ansible_private_ip}`: IP privado do Ansible Control Node

**Ficheiro gerado**: `ansible-playbooks/inventory.ini`

**Usado por**: `ansible-integration.tf`

---

### 2. `template_files/ansible_machine/setup_logger.yml.tpl`

**Propósito**: Template para gerar o playbook Ansible que configura logging no Runner.

**Variáveis substituídas**: Nenhuma (template estático)

**Ficheiro gerado**: `ansible-playbooks/setup_logger.yml`

**O que o playbook faz**:
1. Copia script de logging para o Runner
2. Cria systemd service e timer
3. Configura execução automática a cada 5 segundos

**Usado por**: `ansible-tasks.tf`

**Documentação detalhada**: Ver [template-files.md](./template-files.md)

---

## Ordem de Execução

Quando executas `terraform apply`, os recursos são criados nesta ordem:

1. **Data Source** (`aws_ami.amazon_linux`) - Busca a AMI mais recente
2. **Networking** - Infraestrutura de rede
   - VPC (`main_vpc`)
   - Subnet (`main_subnet`)
   - Internet Gateway (`main_igw`)
   - Route Table (`main_rt`)
   - Route Table Association (`main_rta`)
3. **Security Groups** (`ansible_sg`, `runner_sg`) - Dependem da VPC
4. **EC2 Instances** - Dependem de Security Groups e Subnet
   - Ansible Control Node (`ansible_control`)
   - Runner Machine (`machine_runner`)
5. **Local Files** - Geração de inventory e playbooks
   - `ansible_inventory` (depende das instâncias)
   - `ansible_playbook`
6. **Provisioning** - Execução de tarefas Ansible
   - `copy_ansible_files` (depende de tudo anterior)
   - Copia ficheiros e executa playbooks
7. **Outputs** - Mostrados no final

## Comandos Terraform Úteis

### Inicialização
```bash
cd terraform/DEV
terraform init
```

### Validação
```bash
terraform validate
terraform fmt
```

### Planeamento
```bash
terraform plan
terraform plan -var="environment=PROD"
terraform plan -out=tfplan
```

### Aplicação
```bash
terraform apply
terraform apply -auto-approve
terraform apply tfplan
```

### Ver Outputs
```bash
terraform output
terraform output ansible_public_ip
terraform output -json
```

### Destruição
```bash
terraform destroy
terraform destroy -target=aws_instance.machine_runner
```

### Ver Estado
```bash
terraform show
terraform state list
terraform state show aws_instance.ansible_control
```

## Variáveis de Ambiente

Podes usar variáveis de ambiente para configurar:

```bash
# AWS Credentials
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION="eu-central-1"

# Terraform variables
export TF_VAR_environment="DEV"
export TF_VAR_my_ip="123.45.67.89/32"
```

## Ficheiros Gerados pelo Terraform

Após executar `terraform init` e `terraform apply`:

```
terraform/DEV/
├── .terraform/              # Plugins e modules (não commitar)
├── .terraform.lock.hcl      # Lock file de providers
├── terraform.tfstate        # Estado atual (SENSÍVEL - não commitar)
├── terraform.tfstate.backup # Backup do estado
└── tfplan                   # Plano guardado (opcional)
```

**⚠️ IMPORTANTE**:
- **NUNCA** commites `terraform.tfstate` - contém informação sensível!
- Adiciona ao `.gitignore`:
  ```
  .terraform/
  *.tfstate
  *.tfstate.backup
  tfplan
  ```

## Estado Atual do Projeto

### Completo ✅
1. **Infraestrutura de Rede**:
   - ✅ VPC com subnet isolada
   - ✅ Internet Gateway configurado
   - ✅ Route Tables configuradas

2. **Instâncias EC2**:
   - ✅ Ansible Control Node com tags e security groups
   - ✅ Runner Machine com tags, security groups e outputs
   - ✅ User data configurado em ambas

3. **Integração Terraform-Ansible**:
   - ✅ Geração automática de inventory
   - ✅ Geração de playbooks a partir de templates
   - ✅ Execução automática de playbooks

4. **Scripts e Templates**:
   - ✅ Scripts modulares organizados
   - ✅ Templates para geração dinâmica
   - ✅ Script de execução do Terraform

**Nota**: Para melhorias futuras, consultar `todo.md` na raiz do projeto.

## Troubleshooting

### "Error: No valid credential sources found"
- Configura AWS credentials: `aws configure`
- Ou usa variáveis de ambiente AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY

### "Error: module.x is not yet installed"
- Executa: `terraform init`

### "Error: state lock"
- Outra pessoa/processo está a usar o state
- Se tiveres certeza que não: `terraform force-unlock <ID>`

### Mudanças não esperadas
- Verifica: `terraform plan` antes de `apply`
- Usa: `terraform plan -out=tfplan` e depois `terraform apply tfplan`