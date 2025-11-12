# TODO - Melhorias Futuras









## Lista de afazeres relativo a arquitectura

| TAREFA | COMPLETADO | DESCRICAO |
|-|-|-|
|Remover o node que é responsavel pelo ansible | | Quem trata disso é a Runner [FLUXO](#FLOW) | 
|||
|||
|||
|||
|||
|||
|||
|||




### Flow

What does it exist currently:

<img src="docs/images/original_flow.jng" width=200 />


There is a responsible machine that is initalized by the terraform and it receaves all the terror state files and runs the task. 






















## 1. Organização do Código

### Estrutura de Ficheiros
- [ ] Criar `variables.tf` separado para todas as variáveis
- [ ] Criar `outputs.tf` separado para todos os outputs
- [ ] Considerar separar resources por tipo (networking.tf, compute.tf, etc.)

### Versionamento
- [ ] Adicionar `.gitignore` apropriado
  - Ignorar `*.tfstate`, `*.tfstate.backup`, `.terraform/`, `tfplan`
  - Ignorar ficheiros gerados: `ansible-playbooks/*.ini`, `ansible-playbooks/*.yml`
- [ ] Adicionar `.terraform.lock.hcl` ao Git (lock de providers)

---

## 2. Segurança

### SSH Keys
- [ ] Automatizar geração de SSH keys via Terraform
  - Adicionar `tls_private_key` resource para gerar par de chaves
  - Criar novo ficheiro `keys.tf` ou adicionar ao `main.tf`
- [ ] Atualizar `ansible-machine.tf` user_data
  - Salvar private key em `/home/ansible/.ssh/id_ed25519`
  - Configurar permissões corretas (chmod 600, chown ansible:ansible)
- [ ] Atualizar `runner-machine.tf` user_data
  - Adicionar public key a `/home/ansible/.ssh/authorized_keys`
  - Configurar permissões corretas

### Credenciais e Secrets
- [ ] Usar AWS Secrets Manager para credenciais sensíveis
- [ ] Remover hardcoded IP em `var.my_ip` - usar data source ou SSM Parameter
- [ ] Considerar usar AWS Systems Manager Session Manager em vez de SSH direto

### Terraform State
- [ ] Implementar backend remoto (S3 + DynamoDB)
  - Criar S3 bucket para state
  - Criar DynamoDB table para state locking
  - Ativar versionamento no S3
- [ ] Adicionar encryption ao state (server-side encryption)
- [ ] Configurar state locking para prevenir modificações concorrentes

---

## 3. Networking e Infraestrutura

### Subnets
- [ ] Implementar subnet privada para Runner Machine
- [ ] Implementar subnet pública apenas para Ansible Control
- [ ] Criar NAT Gateway para subnet privada aceder à Internet

### Alta Disponibilidade
- [ ] Distribuir recursos em múltiplas Availability Zones
- [ ] Considerar Auto Scaling Group para Runners
- [ ] Implementar Load Balancer se necessário

### Segurança de Rede
- [ ] Implementar Network ACLs para camada extra de segurança
- [ ] Ativar VPC Flow Logs para monitoring de tráfego
- [ ] Restringir `var.my_ip` para apenas IPs específicos conhecidos

---

## 4. Automação e CI/CD

### GitHub Actions
- [ ] Criar workflow para `terraform plan` em Pull Requests
- [ ] Criar workflow para `terraform apply` em merge para main
- [ ] Adicionar validação automática (`terraform validate`, `terraform fmt -check`)
- [ ] Implementar testes de segurança (tfsec, checkov)

### Testes
- [ ] Adicionar testes automatizados com Terratest
- [ ] Criar testes de integração para Ansible playbooks
- [ ] Implementar smoke tests após deployment

### Scripts
- [ ] Melhorar `terraform_execution.sh`
  - Usar AWS credentials file em vez de parâmetros
  - Adicionar logging detalhado
  - Adicionar confirmação antes de destroy
- [ ] Criar script de validação pré-commit
- [ ] Adicionar script para verificar conformidade de segurança

---

## 5. Monitoring e Observabilidade

### Logs
- [ ] Implementar CloudWatch Logs para instâncias EC2
- [ ] Centralizar logs de aplicação
- [ ] Configurar log retention policies

### Métricas
- [ ] Ativar CloudWatch detailed monitoring
- [ ] Criar dashboards customizados
- [ ] Configurar métricas customizadas (uso de disco, memória)

### Alertas
- [ ] Configurar SNS topics para notificações
- [ ] Criar alarmes para CPU, memória, disco
- [ ] Alertas para falhas de deployment
- [ ] Alertas para mudanças de segurança (security group changes)

---

## 6. Ansible

### Organização
- [ ] Converter playbooks simples em Ansible Roles
- [ ] Criar role para Runner setup
- [ ] Criar role para logging/monitoring setup

### Dynamic Inventory
- [ ] Implementar AWS Dynamic Inventory
- [ ] Usar tags para descobrir instâncias automaticamente
- [ ] Eliminar necessidade de inventory estático

### Ansible Vault
- [ ] Usar Ansible Vault para secrets
- [ ] Encriptar variáveis sensíveis em playbooks
- [ ] Integrar vault password com AWS Secrets Manager

### Melhoria de Playbooks
- [ ] Adicionar handlers para restart de serviços
- [ ] Implementar idempotência em todas as tasks
- [ ] Adicionar testes com Molecule

---

## 7. Documentação

- [x] Criar documentação para networking (VPC, Subnet)
- [x] Criar documentação para Ansible integration
- [x] Criar documentação para scripts
- [x] Criar documentação para template files
- [x] Atualizar README.md com índice completo
- [ ] Adicionar diagramas de arquitetura (draw.io, mermaid)
- [ ] Criar guia de troubleshooting expandido
- [ ] Documentar disaster recovery procedures

---

## 8. Multi-Ambiente (DEV/PROD)

### Workspaces
- [ ] Implementar Terraform workspaces para DEV/PROD
- [ ] Criar `terraform.tfvars` separados por ambiente
- [ ] Documentar processo de promoção DEV → PROD

### Diferenças de Configuração
- [ ] DEV: Instâncias menores (t2.micro)
- [ ] PROD: Instâncias apropriadas para carga
- [ ] PROD: Backup automático habilitado
- [ ] PROD: Multi-AZ deployment

---

## 9. Backup e Disaster Recovery

- [ ] Implementar EBS snapshots automáticos
- [ ] Criar processo de backup do Terraform state
- [ ] Documentar procedimento de restore
- [ ] Testar DR plan regularmente

---

## 10. Cost Optimization

- [ ] Implementar tags de cost allocation
- [ ] Configurar AWS Cost Explorer alerts
- [ ] Considerar Reserved Instances para PROD
- [ ] Implementar auto-shutdown para DEV fora de horário
- [ ] Usar Spot Instances onde apropriado

---

## Prioridades

### Alta Prioridade (Fazer primeiro)
1. Backend remoto para Terraform state (Segurança #2.3)
2. Automatizar SSH keys (Segurança #2.1)
3. Organização de ficheiros - variables.tf e outputs.tf (Organização #1.1)
4. .gitignore apropriado (Organização #1.2)

### Média Prioridade
1. Subnet privada para Runner (Networking #3.1)
2. CloudWatch monitoring básico (Monitoring #5.1, #5.2)
3. Ansible Roles (Ansible #6.1)
4. Diagramas de arquitetura (Documentação #7)

### Baixa Prioridade (Nice to have)
1. GitHub Actions CI/CD (Automação #4.1)
2. Alta disponibilidade multi-AZ (Networking #3.2)
3. AWS Dynamic Inventory (Ansible #6.2)
4. Cost optimization (Cost #10)
