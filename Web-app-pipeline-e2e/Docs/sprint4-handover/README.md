# Sprint 4 Project Handover (Enterprise Support Edition)

## 1. Purpose of this Handover Pack
This handover package is for operations, support, and next-phase engineering teams.
It documents:
- full repository inventory and purpose mapping
- AWS, CI/CD, Jenkins, Terraform, and Ansible configuration references
- operational command runbooks for day-2 support
- troubleshooting and support ownership boundaries

## 2. Scope
This handover covers the current repository state for:
- application delivery pipeline: `Jenkinsfile.sprint4`
- infrastructure pipeline: `Jenkinsfile.terraform`
- configuration pipeline: `Jenkinsfile.ansible`
- Terraform IaC under `terraform/`
- Ansible automation under `ansible/`
- Kubernetes manifests under `k8s/`
- Jenkins seed-job automation under `ci/jenkins/`
- support scripts under `scripts/`

## 3. Document Index
1. `01-repository-file-catalog.md`
- full folder/file catalog with purpose and usage

2. `02-configuration-reference.md`
- runtime configuration, parameter defaults, credentials, environment variables, and integration points

3. `03-operations-commands.md`
- practical commands for AWS, Terraform, Ansible, Jenkins, Docker, Kubernetes, and CI/CD support operations

4. `04-support-runbook.md`
- incident triage model, common failure patterns, rollback guidance, and ownership map

5. `05-execution-flow-diagrams.md`
- visual execution flow and sequence diagrams for pipeline operations

## 4. Delivery Model (Quick Summary)
- Terraform pipeline provisions or updates platform resources.
- Ansible pipeline configures management host and validates connectivity/tooling.
- Sprint4 pipeline builds/tests app, pushes image to ECR, then deploys to EKS.

## 5. Critical Credentials and Access (High-Level)
- Jenkins AWS credentials ID (default used in pipelines: `awsId`)
- Jenkins SSH private key credentials for Ansible host access (default: `management-ec2-ssh-key`)
- IAM permissions for ECR, EKS, EC2, S3, DynamoDB, STS, and Terraform actions

## 6. Operational Principle
Use the pipelines in this order unless incident response dictates otherwise:
1. `Jenkinsfile.terraform`
2. `Jenkinsfile.ansible`
3. `Jenkinsfile.sprint4`

## 7. Support Note
All commands in this handover are written to be copy/paste ready and environment-driven.
Always run in a controlled branch and preserve audit trails via Jenkins build logs and Git history.
