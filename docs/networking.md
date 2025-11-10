# Networking Infrastructure

## Visão Geral

Este documento descreve a infraestrutura de rede criada para o projeto, incluindo VPC, Subnet, Internet Gateway e Route Tables. Todos estes componentes são definidos no ficheiro `sub_net_enviroment.tf`.

## Componentes de Rede

### 1. VPC (Virtual Private Cloud)

**Recurso**: `aws_vpc.main_vpc`

#### Especificações
- **CIDR Block**: `10.0.0.0/24` (permite até 256 endereços IP)
- **Instance Tenancy**: `default`
- **Nome**: `main_vpc`

Rede virtual isolada na AWS onde todos os recursos do projeto são criados.

---

### 2. Subnet

**Recurso**: `aws_subnet.main_subnet`

#### Especificações
- **CIDR Block**: `10.0.0.0/24` (mesmo que a VPC - subnet única)
- **Nome**: `main_subnet`

Subdivisão da VPC que usa todo o range de IPs. Todas as instâncias (Ansible Control e Runner) estão nesta subnet.

**Vantagens**:
- ✅ Comunicação direta via IPs privados
- ✅ Baixa latência
- ✅ Sem custos de transferência
- ✅ Configuração simples

---

### 3. Internet Gateway

**Recurso**: `aws_internet_gateway.main_igw`

Permite comunicação entre a VPC e a Internet. Necessário para:
- SSH access às instâncias EC2
- Download de packages (yum update, ansible install)
- Acesso a serviços externos

---

### 4. Route Table

**Recurso**: `aws_route_table.main_rt`

Define as rotas de tráfego:
- **Route**: `0.0.0.0/0` → Internet Gateway
- Todo o tráfego destinado à Internet é encaminhado via Internet Gateway

---

### 5. Route Table Association

**Recurso**: `aws_route_table_association.main_rta`

Associa a Route Table à Subnet, aplicando as regras de roteamento.

---

## Arquitetura de Rede

```
Internet
    ↕
Internet Gateway (main_igw)
    ↕
Route Table (main_rt)
    ↕
VPC (10.0.0.0/24)
    └── Subnet (10.0.0.0/24)
        ├── Ansible Control Node (10.0.0.X)
        └── Runner Machine (10.0.0.Y)
```

### Fluxo de Tráfego

#### Tráfego de Entrada (SSH do exterior)
1. Internet → Internet Gateway
2. Internet Gateway → Route Table
3. Route Table → Subnet → Instância EC2

#### Tráfego de Saída (yum update, downloads)
1. Instância EC2 → Subnet → Route Table
2. Route Table → Internet Gateway
3. Internet Gateway → Internet

#### Comunicação entre Instâncias
1. Ansible Control (10.0.0.X) → Subnet → Runner (10.0.0.Y)
   - **Direto**, sem passar pelo Internet Gateway
   - **Privado** e **seguro**

---

## Security Groups e Networking

Os Security Groups trabalham em conjunto com a rede:

### Ansible Control Node
- **Security Group**: `ansible_sg`
- **Ingress**: SSH (22) do teu IP
- **Egress**: Todo o tráfego permitido
- **VPC**: `aws_vpc.main_vpc.id`

### Runner Machine
- **Security Group**: `runner_sg`
- **Ingress**: Todo o tráfego do Ansible Control Node (`ansible_sg`)
- **Egress**: Todo o tráfego permitido
- **VPC**: `aws_vpc.main_vpc.id`

**Nota Importante**: Security Groups são **stateful** - se permites tráfego de entrada, a resposta é automaticamente permitida.

---

## Configuração de IPs

### IPs Públicos
Ambas as instâncias têm IPs públicos ativados (`associate_public_ip_address = true`):
- ✅ Permite SSH do exterior
- ✅ Permite download de packages
- ⚠️ Em produção, considera usar apenas IPs públicos no Ansible Control Node

### IPs Privados
Os IPs privados são atribuídos automaticamente pela AWS dentro do range `10.0.0.0/24`:
- **Ansible Control**: 10.0.0.X (exemplo: 10.0.0.4)
- **Runner**: 10.0.0.Y (exemplo: 10.0.0.5)

Estes IPs são usados para comunicação interna (via Ansible).

---

## Boas Práticas Implementadas

- ✅ VPC isolada para o projeto
- ✅ Subnet configurada para comunicação interna
- ✅ Internet Gateway para acesso externo
- ✅ Route Table configurada corretamente
- ✅ Security Groups por tipo de instância

**Nota**: Para melhorias futuras, consultar `todo.md` na raiz do projeto.

---

## Como Verificar a Configuração

### Ver os recursos criados
```bash
# Ver a VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=main_vpc"

# Ver a Subnet
aws ec2 describe-subnets --filters "Name=tag:Name,Values=main_subnet"

# Ver o Internet Gateway
aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=main-igw"

# Ver a Route Table
aws ec2 describe-route-tables --filters "Name=tag:Name,Values=main-route-table"
```

### Verificar via Terraform
```bash
cd terraform/DEV
terraform state list
terraform state show aws_vpc.main_vpc
terraform state show aws_subnet.main_subnet
```

---

## Troubleshooting

### "Não consigo fazer SSH para a instância"
- ✅ Verifica que o Internet Gateway está anexado à VPC
- ✅ Verifica que a Route Table tem a route `0.0.0.0/0` para o IGW
- ✅ Verifica que a subnet está associada à Route Table
- ✅ Verifica que a instância tem IP público

### "Ansible Control não consegue conectar ao Runner"
- ✅ Ambas as instâncias estão na mesma subnet?
- ✅ Security Group do Runner permite tráfego do Ansible Control?
- ✅ Estás a usar o IP **privado** do Runner no inventory?

### "Instâncias não conseguem fazer downloads"
- ✅ Internet Gateway está criado e anexado?
- ✅ Route Table tem route para `0.0.0.0/0` via IGW?
- ✅ Security Group tem egress permitido?

---

## Referências

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider - VPC](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
- [CIDR Block Calculator](https://www.ipaddressguide.com/cidr)
