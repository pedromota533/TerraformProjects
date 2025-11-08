TODO - Automate SSH Key Setup Between Ansible Control and Runner

1. Add tls_private_key resource to generate SSH key pair automatically
   - This will create a key pair using Terraform
   - Add to runner-machine.tf or create a new keys.tf file

2. Update Ansible Control Node user_data (ansible-machine.tf)
   - Save the generated private key to /home/ansible/.ssh/id_ed25519
   - Set correct permissions (chmod 600)
   - Set correct ownership (chown ansible:ansible)

3. Update Runner Machine user_data (runner-machine.tf)
   - Add the generated public key to /home/ansible/.ssh/authorized_keys
   - Create .ssh directory if it doesnt exist
   - Set correct permissions (chmod 700 for .ssh, chmod 600 for authorized_keys)
   - Set correct ownership (chown ansible:ansible)

4. Add outputs for runner machine (runner-machine.tf)
   - runner_instance_id
   - runner_public_ip
   - runner_private_ip

5. Test the automated setup
   - Destroy and recreate infrastructure
   - SSH to Ansible control node
   - Switch to ansible user
   - Create inventory file with runner private IP
   - Test: ansible runners -i inventory -m ping
   - Should get pong response without manual key setup

6. Optional: Create inventory file automatically
   - Could use Terraform local_file resource to create inventory
   - Or use template_file to generate it
   - Save it on Ansible control node during user_data execution
