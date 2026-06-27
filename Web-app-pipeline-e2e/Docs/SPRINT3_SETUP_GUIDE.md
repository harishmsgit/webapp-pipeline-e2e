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

### Required Jenkins Plugins

**Before running the Ansible pipeline, install these plugins in Jenkins:**

1. **AWS Credentials Plugin** (usually pre-installed)
   - Binds AWS credentials to the pipeline

No extra SSH Agent plugin is required for the current pipeline because the Ansible stages use Jenkins' built-in `withCredentials([sshUserPrivateKey(...)])` binding.

### Jenkins Agent Requirements

Install these on the Jenkins agent (machine running the pipeline):

- Terraform
- Python 3 with outbound HTTPS access so the Ansible pipeline can bootstrap user-local `pip`, `python3-venv`, and `ansible-core`
- AWS CLI
- Git

The Jenkins agent should either have `python3-venv`/`python3-pip` pre-installed, or support passwordless sudo for package installation. If the agent cannot install packages, pre-install those runtime dependencies before running the pipeline.

### Jenkins Credentials

Create these Jenkins credentials in Jenkins under Manage Jenkins → Manage Credentials:

- `awsId` - AWS credentials or use an EC2 instance profile.
- `management-ec2-ssh-key` - SSH Username with private key credential for the management EC2 instance.

Use these exact values:

- Kind: `SSH Username with private key`
- ID: `management-ec2-ssh-key`
- Username: `ubuntu`
- Private key: contents of the PEM file that matches the EC2 key pair used by the management instance

If Jenkins reports `Could not find credentials entry with ID 'management-ec2-ssh-key'`, the credential has not been created or the job is not using the same credential store/scope.

## Jobs

Create a Jenkins Pipeline job for Terraform:

- Job name: `webapp-terraform`
- Job type: Pipeline
- Definition: Pipeline script from SCM
- Script Path: `Web-app-pipeline-e2e/Jenkinsfile.terraform`

Create a second Jenkins Pipeline job for Ansible:

- Job name: `webapp-ansible-config`
- Job type: Pipeline
- Definition: Pipeline script from SCM
- Script Path: `Web-app-pipeline-e2e/Jenkinsfile.ansible`

The Terraform job manages the handoff to the Ansible job. When `RUN_ANSIBLE_AFTER_APPLY` is enabled, the Terraform pipeline triggers the Ansible job after `terraform apply` succeeds.

The Terraform job parameter `ANSIBLE_JOB_NAME` must match the Ansible job name. If the Ansible job is named `webapp-ansible-config`, keep the default value.

Pipeline flow:

```text
webapp-terraform
        |
        | after terraform apply succeeds
        v
webapp-ansible-config
```

The Terraform job passes these values into the Ansible job:

- `AWS_REGION`
- `TF_STATE_BUCKET`
- `LOCK_TABLE`
- `ENVIRONMENT`
- `AWS_CREDENTIALS_ID`
- `SSH_PRIVATE_KEY_CREDENTIALS_ID`
- `REMOTE_USER`

## Production Environment

For production, use separate Jenkins jobs, credentials, state storage, and Terraform workspace values. Do not reuse development credentials or state.

Recommended production jobs:

- Terraform job name: `webapp-terraform-prod`
- Ansible job name: `webapp-ansible-prod`

Both jobs can use the same repository files:

- Terraform Script Path: `Web-app-pipeline-e2e/Jenkinsfile.terraform`
- Ansible Script Path: `Web-app-pipeline-e2e/Jenkinsfile.ansible`

Use these production parameter values in the Terraform job:

```text
ENVIRONMENT=prod
ANSIBLE_JOB_NAME=webapp-ansible-prod
AWS_REGION=ap-south-1
TF_STATE_BUCKET=webapp-prod-terraform-state
LOCK_TABLE=webapp-prod-terraform-lock
SSH_PRIVATE_KEY_CREDENTIALS_ID=prod-management-ec2-ssh-key
REMOTE_USER=ubuntu
RUN_ANSIBLE_AFTER_APPLY=true
```

Production flow:

```text
webapp-terraform-prod
        |
        | after terraform apply succeeds
        v
webapp-ansible-prod
```

Production controls:

- Use a dedicated production S3 state bucket or state key.
- Use a dedicated production DynamoDB lock table.
- Use a dedicated production EC2 key pair and Jenkins SSH credential.
- Restrict `allowed_ssh_cidr` to your office VPN, bastion, or Jenkins agent IP range.
- Add a manual approval stage before `terraform apply` if the job is used for real production infrastructure.
- Scope Jenkins credentials so only production jobs can access production AWS and SSH secrets.
- Keep `RUN_ANSIBLE_AFTER_APPLY=false` during first production dry runs, then enable it after the playbook is validated.

## Local Validation

After Terraform has created the EC2 instance:

```bash
terraform -chdir=terraform output -json > ansible/terraform-outputs.json
python3 scripts/generate_ansible_inventory.py \
  --terraform-output ansible/terraform-outputs.json \
  --inventory ansible/inventories/generated/hosts.ini \
  --remote-user ubuntu
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventories/generated/hosts.ini ansible/playbooks/configure-management.yml
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventories/generated/hosts.ini ansible/playbooks/validate-management.yml
```
