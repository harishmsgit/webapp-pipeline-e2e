# Sprint 3 Setup Guide: Ansible Configuration Management

Sprint 3 adds an Ansible-driven configuration stage after Terraform provisioning. The Ansible pipeline reads Terraform outputs, generates an inventory for the management EC2 instance, installs Docker, kubectl, AWS CLI v2, and validates the resulting host configuration.

## Files Added

- `Jenkinsfile.ansible` - Jenkins pipeline for configuration management.
- `ansible/playbooks/configure-management.yml` - configures the EC2 management host.
- `ansible/playbooks/validate-management.yml` - verifies Docker, kubectl, and AWS CLI.
- `scripts/generate_ansible_inventory.py` - creates inventory from `terraform output -json`.
- `ansible/roles/*` - reusable roles for common packages, Docker, kubectl, and AWS CLI.

## Terraform Requirement

Set `management_key_name` to an existing EC2 key pair name before running Terraform:

```hcl
management_key_name = "your-ec2-key-pair-name"
```

The default is `null` to avoid changing existing environments, but SSH-based Ansible requires a key pair on the management EC2 instance.

## Jenkins Prerequisites

Install these on the Jenkins agent:

- Terraform
- Ansible
- AWS CLI
- Python 3
- Jenkins `SSH Agent` plugin
- Jenkins AWS credentials binding plugin

Create these Jenkins credentials:

- `aws-credentials` - AWS credentials or use an EC2 instance profile.
- `management-ec2-ssh-key` - SSH private key matching `management_key_name`.

## Jobs

Create a Jenkins Pipeline job for Terraform using `Jenkinsfile.terraform`.

Create a second Jenkins Pipeline job for Ansible using `Jenkinsfile.ansible`. Name it `webapp-ansible-config` or pass another name through the Terraform job parameter `ANSIBLE_JOB_NAME`.

When `RUN_ANSIBLE_AFTER_APPLY` is enabled, the Terraform pipeline triggers the Ansible job after `terraform apply` succeeds.

## Local Validation

After Terraform has created the EC2 instance:

```bash
terraform -chdir=terraform output -json > ansible/terraform-outputs.json
python3 scripts/generate_ansible_inventory.py \
  --terraform-output ansible/terraform-outputs.json \
  --inventory ansible/inventories/generated/hosts.ini \
  --remote-user ec2-user
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventories/generated/hosts.ini ansible/playbooks/configure-management.yml
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventories/generated/hosts.ini ansible/playbooks/validate-management.yml
```
