# Ansible issues fixed and how

## 1. SSH authentication failed from Jenkins to the management host
### Problem
The Jenkins agent could reach the EC2 host on port 22, but Ansible was failing to authenticate with the SSH private key.

### Fix
- Updated the Jenkins pipeline to explicitly pass the Jenkins SSH private key file into Ansible.
- Exported `ANSIBLE_SSH_PRIVATE_KEY_FILE` and `ANSIBLE_PRIVATE_KEY_FILE` before running `ansible-playbook`.
- Passed the key path as extra variables to the playbook.

### Result
Ansible could establish an SSH connection to the management EC2 host successfully.

### Commands used
```bash
ansible-playbook -vvv -i ansible/inventories/generated/hosts.ini ansible/playbooks/configure-management.yml \
  -e "aws_region=ap-south-1" \
  -e "eks_cluster_name=webapp-eks-cluster" \
  -e "ansible_user=ubuntu" \
  -e "ansible_ssh_private_key_file=$SSH_KEY_FILE" \
  -e "ansible_private_key_file=$SSH_KEY_FILE"
```

---

## 2. Docker role failed because `docker_users` was undefined
### Problem
The Docker role attempted to loop over `docker_users`, but the variable was not always defined.

### Fix
- Added a safe fallback in the Docker role so it uses `ubuntu` when `docker_users` is missing.

### Result
The Docker role no longer fails at the user-group task.

---

## 3. Kubectl role failed because `kubectl_version` was undefined
### Problem
The Kubectl role tried to build a download URL using `kubectl_version`, but the variable was missing.

### Fix
- Added a default fallback value for `kubectl_version` in the role.

### Result
The Kubectl installation step now proceeds without failing on an undefined variable.

### Commands used
```bash
python3 scripts/generate_ansible_inventory.py \
  --terraform-output ansible/terraform-outputs.json \
  --inventory ansible/inventories/generated/hosts.ini \
  --remote-user ubuntu
cat ansible/inventories/generated/hosts.ini
```

---

## 4. Inventory generation and host resolution
### Problem
The pipeline needed to generate the Ansible inventory from Terraform output and verify the host before running the playbook.

### Fix
- Confirmed the inventory file contained the correct `ansible_host` value.
- Verified that the host was reachable before running the playbook.

### Result
The inventory and host resolution now match the management EC2 instance correctly.
