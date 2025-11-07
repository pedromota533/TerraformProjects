# Visão Geral dos Ficheiros Terraform

## Estrutura do Projeto

```
TerraformProjects/
├── terraform/
│   └── DEV/
│       ├── terraform.tf          # Configuração do Terraform e providers
│       ├── main.tf               # Provider AWS, variáveis e AMI data source
│       ├── ansible-machine.tf    # Ansible Control Node
│       └── runner-machine.tf     # Runner/Managed Machine
├── scripts/                      # Scripts modulares para configuração
│   ├── ansible-control/
│   │   └── setup-user.sh         # Setup do user ansible (sudo restrito)
│   └── runner/
│       └── setup-user.sh         # Setup do user ansible (sudo completo)
├── docs/                         # Documentação
└── README.md                     # Visão geral do projeto
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
1. **`aws_instance.machine_runner`**: Instância EC2 da Runner Machine

**Status**:
- ✅ Instância definida
- ✅ User data configurado
- ⚠️ **Faltam**: Tags, Security Group (`runner_sg`), Outputs

**Documentação detalhada**: Ver [runner-machine.md](./runner-machine.md)

---

## Scripts de Configuração

Os scripts modulares em `scripts/` são usados pelos ficheiros Terraform para configurar os users nas instâncias EC2.

### 1. `scripts/ansible-control/setup-user.sh`

**Propósito**: Configura o user `ansible` no Ansible Control Node com sudo **restrito**.

**Conteúdo**:
```bash
#!/bin/bash
# Setup user for Ansible Control Node

# Create ansible user
useradd -m -s /bin/bash ansible

# Sudo apenas para comandos Ansible
echo "ansible ALL=(ALL) NOPASSWD: /usr/bin/ansible, /usr/bin/ansible-playbook, /usr/bin/ansible-pull, /usr/bin/ansible-galaxy, /usr/bin/ansible-vault" >> /etc/sudoers.d/ansible

chmod 0440 /etc/sudoers.d/ansible
```

**O que faz**:
- Cria o user `ansible`
- Configura sudo **apenas** para comandos Ansible (segurança)
- Define permissões corretas no ficheiro sudoers

**Usado por**: `ansible-machine.tf` via `file()` function

---

### 2. `scripts/runner/setup-user.sh`

**Propósito**: Configura o user `ansible` na Runner Machine com sudo **completo**.

**Conteúdo**:
```bash
#!/bin/bash
# Setup user for Runner Machine (Managed Node)

# Create ansible user
useradd -m -s /bin/bash ansible

# Sudo completo (sem password)
echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible

chmod 0440 /etc/sudoers.d/ansible
```

**O que faz**:
- Cria o user `ansible`
- Configura sudo **completo** para permitir gestão total via Ansible
- Define permissões corretas no ficheiro sudoers

**Usado por**: `runner-machine.tf` via `file()` function

---

### Vantagens dos Scripts Modulares

- ✅ **Manutenção fácil**: Alterar um script atualiza todas as instâncias
- ✅ **Reutilização**: Mesmo script para DEV e PROD
- ✅ **Versionamento**: Scripts no Git para histórico
- ✅ **Testável**: Podes testar scripts independentemente
- ✅ **Legibilidade**: Código Terraform mais limpo

---

## Ordem de Execução

Quando executas `terraform apply`, os recursos são criados nesta ordem:

1. **Data Source** (`aws_ami.amazon_linux`) - Busca a AMI
2. **Security Groups** (`ansible_sg`, `runner_sg`) - Criados primeiro (sem dependências)
3. **EC2 Instances** (`ansible_control`, `machine_runner`) - Dependem dos Security Groups
4. **Outputs** - Mostrados no final

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

## Próximos Passos

Para completar o projeto:

1. **runner-machine.tf**:
   - [ ] Adicionar tags à instância
   - [ ] Criar `aws_security_group.runner_sg`
   - [ ] Adicionar outputs (IPs, instance ID)

2. **Organização**:
   - [ ] Considerar criar `variables.tf` separado
   - [ ] Considerar criar `outputs.tf` separado
   - [ ] Adicionar `.gitignore` apropriado

3. **Segurança**:
   - [ ] Usar AWS Secrets Manager para credenciais
   - [ ] Implementar backend remoto (S3 + DynamoDB) para state
   - [ ] Adicionar encryption ao state

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