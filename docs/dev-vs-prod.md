# DEV vs PROD: Diferenças e Considerações

## Visão Geral

Este projeto usa a variável `environment` para controlar o comportamento da infraestrutura em diferentes ambientes. A configuração é modular e usa scripts em `scripts/` para facilitar manutenção.

## Principais Configurações de Segurança

### 1. Root SSH Access

**Em TODOS os ambientes (DEV e PROD):**
- **Status**: ❌ **SEMPRE DESATIVADO**
- **Razão**: Segurança - previne ataques e acessos não autorizados
- **Implementação**: Configuração SSH segura por defeito (sem alterações ao sshd_config)

**Alternativa segura**: Usa os users `ec2-user` ou `ansible` que têm privilégios adequados via sudo.

### 2. Permissões Sudo por Tipo de Máquina

#### Ansible Control Node
- **User**: `ansible`
- **Sudo**: ✅ **RESTRITO** - Apenas comandos Ansible
- **Comandos permitidos**:
  - `/usr/bin/ansible`
  - `/usr/bin/ansible-playbook`
  - `/usr/bin/ansible-pull`
  - `/usr/bin/ansible-galaxy`
  - `/usr/bin/ansible-vault`
- **Script**: `scripts/ansible-control/setup-user.sh`

#### Runner Machine (Managed Node)
- **User**: `ansible`
- **Sudo**: ✅ **COMPLETO** - Todos os comandos
- **Razão**: Permite que o Ansible execute qualquer tarefa de gestão
- **Script**: `scripts/runner/setup-user.sh`

### 3. Naming e Tags

Todas as resources usam a variável `environment` nos nomes e tags:

#### DEV
- Nome das instâncias: `Ansible-Control-DEV`, `Ansible-Managed-DEV`
- Security Groups: `ansible-control-sg-DEV`, `ansible-managed-sg-DEV`

#### PROD
- Nome das instâncias: `Ansible-Control-PROD`, `Ansible-Managed-PROD`
- Security Groups: `ansible-control-sg-PROD`, `ansible-managed-sg-PROD`

**Vantagem**: Fácil identificação e separação de recursos por ambiente.

## Variáveis que Mudam por Ambiente

### Variável `environment`
```hcl
variable "environment" {
  description = "Environment name (DEV, PROD, etc)"
  type        = string
}
```

**Como usar:**
```bash
# DEV
terraform plan -var="environment=DEV"
terraform apply -var="environment=DEV"

# PROD
terraform plan -var="environment=PROD"
terraform apply -var="environment=PROD"
```

Ou via `terraform.tfvars`:
```hcl
environment = "DEV"
```

### Outras Variáveis que Podem Diferir

#### `my_ip`
Em DEV podes usar um IP mais permissivo, em PROD apenas IPs específicos e controlados.

## Boas Práticas de Segurança

### DEV
- ✅ Root SSH permitido (para testes)
- ✅ Acesso SSH do teu IP pessoal
- ⚠️ Pode ter security groups mais permissivos
- ⚠️ Logs e monitoring podem ser menos rigorosos

**Importante**: Mesmo em DEV, evita expor dados sensíveis!

### PROD
- ❌ Root SSH **DESATIVADO**
- ✅ Acesso SSH apenas de IPs autorizados e controlados
- ✅ Security groups restritivos (princípio do menor privilégio)
- ✅ Logs e monitoring ativos
- ✅ Backups regulares
- ✅ Usar users não-root (como `ansible` ou `ec2-user`)

## Configuração de User Data

### Ansible Control Node

| Ação | DEV | PROD |
|------|-----|------|
| `yum update -y` | ✅ | ✅ |
| Instalar Ansible | ✅ | ✅ |
| Criar user `ansible` | ✅ | ✅ |
| Sudo RESTRITO (apenas Ansible) | ✅ | ✅ |
| Root SSH | ❌ | ❌ |

**Script usado**: `scripts/ansible-control/setup-user.sh`

### Runner Machine

| Ação | DEV | PROD |
|------|-----|------|
| `yum update -y` | ✅ | ✅ |
| Criar user `ansible` | ✅ | ✅ |
| Sudo COMPLETO | ✅ | ✅ |
| Root SSH | ❌ | ❌ |

**Script usado**: `scripts/runner/setup-user.sh`

### Scripts Modulares

A configuração dos users está em scripts separados para facilitar manutenção:

```
scripts/
├── ansible-control/
│   └── setup-user.sh    # Sudo restrito para comandos Ansible
└── runner/
    └── setup-user.sh    # Sudo completo para gestão
```

**Vantagens**:
- ✅ Fácil de manter e atualizar
- ✅ Reutilizável entre ambientes
- ✅ Versionamento no Git
- ✅ Testável independentemente

## Recomendações

### Para DEV
1. Usa para testes e aprendizagem
2. Podes experimentar configurações nos scripts
3. Não uses dados de produção
4. Destrói recursos quando não estiveres a usar (para poupar custos)
5. Testa mudanças nos scripts antes de aplicar em PROD

### Para PROD
1. Root SSH está **sempre desativado** (não há opção para ativar)
2. Documenta todas as mudanças nos scripts
3. Usa SSH keys fortes
4. Implementa monitoring e alertas
5. Faz backups regulares
6. Princípio do menor privilégio (user `ansible` em Control Node tem sudo restrito)
7. Audita acessos regularmente
8. Testa scripts em DEV primeiro

## Como Verificar o Ambiente

Depois do deployment:

```bash
# Ver os outputs para confirmar o environment
terraform output

# SSH para a máquina e verificar
ssh ec2-user@<ip>
echo $HOSTNAME  # Deve incluir DEV ou PROD no nome

# Verificar que root SSH está desativado (seguro)
sudo grep "PermitRootLogin" /etc/ssh/sshd_config
# Resultado esperado: PermitRootLogin no (ou comentado)

# Verificar permissões sudo do user ansible
sudo cat /etc/sudoers.d/ansible

# Ansible Control: Deve mostrar comandos restritos
# Runner: Deve mostrar NOPASSWD:ALL
```

## Troubleshooting

### "Não consigo fazer SSH como root"
- ✅ **Comportamento esperado!** Root SSH está sempre desativado por segurança
- Usa o user `ec2-user` ou `ansible` em vez disso

### "User ansible não consegue executar comando X no Ansible Control"
- ✅ **Comportamento esperado!** No Control Node, sudo está restrito a comandos Ansible
- Para outros comandos, usa o user `ec2-user` que tem sudo completo

### "User ansible não foi criado"
- Verifica os logs do user_data: `sudo cat /var/log/cloud-init-output.log`
- Confirma que o script em `scripts/*/setup-user.sh` está correto
- Verifica permissões do ficheiro script (deve ser legível)

## Migração de DEV para PROD

Quando estiveres pronto para produção:

1. ✅ Testa tudo em DEV primeiro (incluindo scripts)
2. ✅ Documenta a configuração
3. ✅ Verifica que os scripts em `scripts/` estão corretos
4. ✅ Muda `environment` para "PROD"
5. ✅ Revê security groups e permissões
6. ✅ Root SSH está sempre desativado (nada a fazer)
7. ✅ Implementa monitoring
8. ✅ Faz deployment de PROD em separado (não reutilizes recursos de DEV)

```bash
# Workspace separado para PROD (opcional mas recomendado)
terraform workspace new prod
terraform workspace select prod
terraform apply -var="environment=PROD"
```

**Nota**: A configuração de segurança (sem root SSH, sudo restrito) é **idêntica** em DEV e PROD, seguindo boas práticas.