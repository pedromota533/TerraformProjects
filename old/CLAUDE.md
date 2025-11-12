  CONTEXTO

  Projeto AutomaticTask - Automação AWS com Terraform + Ansible para GitHub Self-Hosted Runners

  ARQUITETURA ATUAL

  - 2 EC2s: Ansible Control Node + Runner Machine
  - Ansible roda dentro do Control Node (EC2)
  - Terraform usa templatefile() + local_file para gerar inventory dinamicamente
  - null_resource provisioners executam Ansible automaticamente

  O QUE O ALEXANDRE PEDIU

  "Usar um GitHub runner para correr o pipeline. Dentro desse runner, correm-se os comandos terraform e ansible. Usar terraform
  output para buscar o state existente e obter os IPs das EC2s criadas. Fazer parse com jq."

  ARQUITETURA NOVA

  - ❌ Sem Control Node dedicado
  - ✅ GitHub Runner executa Terraform + Ansible
  - ✅ Terraform cria apenas runners (EC2s)
  - ✅ terraform output -json → jq → extrai IPs
  - ✅ Ansible usa esses IPs para configurar

  WORKFLOW

  terraform apply                           # Cria EC2s
  terraform output -json > outputs.json     # Obtém IPs
  RUNNER_IP=$(cat outputs.json | jq -r '.runner_private_ip.value')
  ansible-playbook -i "$RUNNER_IP," playbook.yml

  CONCEITOS APRENDIDOS

  1. State file guarda TUDO (recursos, IPs, IDs, outputs)
  2. Outputs são apenas uma parte do state file (valores expostos)
  3. terraform output → HCL (não é JSON)
  4. terraform output -json → JSON (usar com jq)
  5. Estrutura: { "nome": { "value": "..." } }
  6. Parse: jq -r '.runner_private_ip.value'

  TAREFAS A FAZER

  1. Remover ansible-machine.tf e ansible-tasks.tf
  2. Criar outputs para IPs dos runners
  3. Testar: terraform apply → output -json → jq
  4. Adaptar Ansible para usar IPs extraídos
  5. Configurar GitHub Runner + workflow

  FICHEIROS CRIADOS

  - perguntas_colega.txt (editado pelo utilizador, mantém questões sobre Terraform State, Integração, Estrutura)
