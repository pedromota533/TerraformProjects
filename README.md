# Tarefa:

Solução automatizada de pipeline que usa AWS & Azure para executar testes e validações, e fornecer feedback sobre os testes eventualmente.

Mais detalhadamente, a configuração deve ser altamente modular, o que significa que os parâmetros devem definir se a configuração vai ser executada ou não.


### Terraform:
- Criação da Network
- Criação dos recursos
- Criação de Variáveis



### Notas:

Para poder executar GitHub Actions dentro do nosso servidor, precisamos do GitHub self-hosted runner.

Preciso perceber porque é que preciso do Ansible, já que no Linux poderia usar apenas bash.

Vamos usar EC2 e Azure VMs


---
### Conceitos de Aprendizagem:
- **Terraform**: Para infraestrutura
- **Ansible:** Para configuração
- **GitHub Actions:** Para CI/CD

---

## Documentação

Documentação detalhada sobre o projeto e componentes:

- **[Visão Geral dos Ficheiros](docs/files-overview.md)** - Estrutura do projeto e descrição de cada ficheiro Terraform
- **[Ansible Control Node](docs/ansible-machine.md)** - Máquina principal que executa o Ansible
- **[Runner Machine](docs/runner-machine.md)** - Máquina gerenciada pelo Ansible (managed node)
- **[DEV vs PROD](docs/dev-vs-prod.md)** - Diferenças entre ambientes e considerações de segurança

---

