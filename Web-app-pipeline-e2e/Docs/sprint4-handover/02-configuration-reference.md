# Configuration Reference (AWS, CI/CD, Terraform, Ansible, Jenkins)

## 1. Jenkins Pipelines and Parameter Defaults

### 1.1 Jenkinsfile.sprint4
Main application delivery pipeline.

Parameters:
- `AWS_REGION` (default: `ap-south-1`)
- `AWS_ACCOUNT_ID` (default: `495013583028`)
- `AWS_CREDENTIALS_ID` (default: `awsId`)
- `ECR_REPO_NAME` (default: `web-app-sprint4`)
- `IMAGE_TAG` (default: empty, auto-resolved)
- `EKS_CLUSTER_NAME` (default: `java-spring-eks`)
- `K8S_NAMESPACE` (default: `webapp`)
- `RUN_DEPLOYMENT` (default: `true`)

Environment values in pipeline:
- `NODE_IMAGE=node:18`
- `KUBECTL_VERSION=v1.30.0`

Stage summary:
1. Initialize context (resolve dirs/image URI/tag)
2. Install dependencies (`npm ci`)
3. Test (`npm test`)
4. Build Docker image
5. Push to ECR
6. Deploy to EKS
7. Verify deployment

### 1.2 Jenkinsfile.terraform
Infrastructure lifecycle pipeline.

Parameters:
- `AWS_REGION=ap-south-1`
- `TF_STATE_BUCKET=harish-terraform-state-bucket`
- `LOCK_TABLE=my-terraform-lock-table`
- `ENVIRONMENT=dev`
- `AWS_CREDENTIALS_ID=awsId`
- `SKIP_BACKEND_CREATION=false`
- `RUN_ANSIBLE_AFTER_APPLY=true`
- `ANSIBLE_JOB_NAME=webapp-ansible-config`
- `SSH_PRIVATE_KEY_CREDENTIALS_ID=management-ec2-ssh-key`
- `REMOTE_USER=ubuntu`

Key behavior:
- validates AWS identity
- prepares backend (S3 + DynamoDB)
- runs `terraform init/validate/plan/apply`
- manages Terraform workspace by branch/environment
- can trigger Ansible job after apply

### 1.3 Jenkinsfile.ansible
Host configuration and validation pipeline.

Parameters:
- `AWS_REGION=ap-south-1`
- `TF_STATE_BUCKET=harish-terraform-state-bucket`
- `LOCK_TABLE=my-terraform-lock-table`
- `ENVIRONMENT=dev`
- `AWS_CREDENTIALS_ID=awsId`
- `SSH_PRIVATE_KEY_CREDENTIALS_ID=management-ec2-ssh-key`
- `REMOTE_USER=ubuntu`

Key behavior:
- reads Terraform outputs
- generates inventory
- resolves management host fallback from AWS
- runs configuration and validation playbooks

## 2. Terraform Configuration

Location: `terraform/`

Important input defaults from `variables.tf`:
- `aws_region = ap-south-1`
- `vpc_cidr = 10.0.0.0/16`
- `public_subnet_cidrs = [10.0.1.0/24, 10.0.2.0/24]`
- `instance_type = t3.medium`
- `allowed_ssh_cidr = 0.0.0.0/0`
- `cluster_name = webapp-eks-cluster`
- `management_key_name = null` (must be supplied for SSH workflows)
- `state_bucket = harish-terraform-state-bucket`
- `lock_table = my-terraform-lock-table`

Example tfvars source: `terraform/terraform.tfvars.example`.

Backend artifacts:
- S3 bucket for state
- DynamoDB table for lock

## 3. Ansible Configuration

Location: `ansible/`

Key vars (`ansible/group_vars/all.yml`):
- `aws_region: ap-south-1`
- `eks_cluster_name: webapp-eks-cluster`
- `kubectl_version: v1.30.0`
- `docker_users: [ubuntu, ec2-user]`

Inventory files:
- template: `ansible/inventories/hosts.ini.example`
- generated: `ansible/inventories/generated/hosts.ini`

Playbooks:
- `ansible/playbooks/configure-management.yml`
- `ansible/playbooks/validate-management.yml`

Roles:
- `common`
- `docker`
- `kubectl`
- `aws_cli`

## 4. AWS and Security Configuration

### 4.1 IAM / Credentials
Required Jenkins credentials:
- AWS credentials (`awsId` by default)
- SSH private key for management host (`management-ec2-ssh-key` by default)

Policy template:
- `jenkins-ecr-policy.json` for ECR push/read permissions

### 4.2 Services Used
- ECR (image registry)
- EKS (cluster + deployment target)
- EC2 (management host)
- S3 (Terraform state)
- DynamoDB (Terraform state lock)
- STS (identity checks)

## 5. CI/CD and Job DSL Configuration

CI support files:
- `ci/branch-env-map.yml`
- `ci/parse_branch_env`
- `ci/parse_branch_env.py`

Jenkins seed and DSL:
- `ci/jenkins/seed-job-config.xml`
- `ci/jenkins/seed_job_pipeline.groovy`
- `ci/jenkins/sprint4_job.groovy`
- `ci/jenkins/sprint4_multibranch.groovy`

Branch-to-environment behavior:
- exact/prefix mappings from YAML
- parser fallback if wrapper not executable
- built-in fallback heuristics in pipeline

## 6. Kubernetes Deployment Configuration

Location: `k8s/`

Key behavior:
- `k8s/deployment.yaml` image placeholder replaced at runtime by Sprint 4 pipeline
- namespace ensure/apply before deployment
- service and HPA applied after deployment
- rollout status check for deployment completion

## 7. Configuration Risks and Controls

Recommended production controls:
- keep secrets only in Jenkins credentials or IAM roles
- narrow IAM policies by least privilege
- lock Terraform state (S3 versioning + DynamoDB lock)
- pin tool versions (Terraform, kubectl, Node image)
- enforce protected branches for pipeline changes
- maintain runbook and change approvals for infra updates
