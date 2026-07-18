# Repository File and Folder Catalog

This catalog lists each current top-level folder and file and explains its purpose.

## A. Top-Level Directories

| Path | Purpose | Primary Consumers |
|---|---|---|
| `.github/` | GitHub workflow automation and CI checks | GitHub Actions, maintainers |
| `ansible/` | Configuration management playbooks, inventories, and roles | `Jenkinsfile.ansible`, Ops |
| `app/` | Node.js web application source and smoke tests | `Jenkinsfile.sprint4`, developers |
| `ci/` | Branch mapping, Jenkins seed scripts, Job DSL files | Jenkins admins |
| `Docs/` | Setup guides, issue notes, defect documentation, handover docs | Support, operations, onboarding |
| `k8s/` | Kubernetes manifests for deploy/service/HPA/namespace | `Jenkinsfile.sprint4` |
| `scripts/` | Utility scripts for backend setup, post-deploy checks, inventory generation | Ops, pipelines |
| `terraform/` | Infrastructure-as-code for AWS resources | `Jenkinsfile.terraform`, platform team |

## B. Top-Level Files

| Path | Purpose | Used By |
|---|---|---|
| `.gitignore` | Ignore rules for local/generated files | Git |
| `Dockerfile` | Root image build file (legacy/auxiliary flow) | GitHub workflow (`.github/workflows/ci.yml`) |
| `jenkins-ecr-policy.json` | IAM policy template for Jenkins ECR permissions | Jenkins/AWS admins |
| `Jenkinsfile.ansible` | Jenkins pipeline for Ansible-based host config/validation | Jenkins job `webapp-ansible-config` or equivalent |
| `Jenkinsfile.sprint4` | Main CI/CD pipeline for app build/test/ECR push/EKS deploy | Sprint 4 delivery job |
| `Jenkinsfile.terraform` | Jenkins pipeline for Terraform infra lifecycle | Terraform Jenkins job |
| `README.md` | Project-level overview and setup summary | All users |
| `SPRINT4_CHANGELOG.md` | Sprint 4 change history and notes | Support, project stakeholders |

## C. .github Files

| Path | Purpose |
|---|---|
| `.github/workflows/ci.yml` | GitHub Actions workflow for repository CI checks/build tasks |

## D. ansible/ Files

| Path | Purpose |
|---|---|
| `ansible/ansible.cfg` | Ansible runtime configuration (defaults, plugin behavior, inventory behavior) |
| `ansible/group_vars/all.yml` | Shared Ansible variables (region, kubectl version, users) |
| `ansible/inventories/hosts.ini.example` | Template inventory for management host definition |
| `ansible/inventories/generated/hosts.ini` | Generated inventory consumed by playbooks/pipeline |
| `ansible/playbooks/configure-management.yml` | Applies management host setup tasks |
| `ansible/playbooks/validate-management.yml` | Validates configured management host and tools |
| `ansible/roles/aws_cli/tasks/main.yml` | AWS CLI installation/config role tasks |
| `ansible/roles/common/tasks/main.yml` | Common baseline package/system tasks |
| `ansible/roles/docker/tasks/main.yml` | Docker installation/user setup tasks |
| `ansible/roles/kubectl/tasks/main.yml` | kubectl installation/verification tasks |

## E. app/ Files

| Path | Purpose |
|---|---|
| `app/.dockerignore` | Excludes unnecessary files from app image context |
| `app/Dockerfile` | Production container build for Node app |
| `app/package-lock.json` | NPM dependency lock for reproducible installs |
| `app/package.json` | Node package metadata and scripts |
| `app/server.js` | HTTP application entry point |
| `app/test.js` | Smoke test runner with dynamic port and health retry logic |

## F. ci/ Files

| Path | Purpose |
|---|---|
| `ci/branch-env-map.yml` | Branch-to-environment mapping for workspace/environment selection |
| `ci/parse_branch_env` | Shell wrapper for branch mapping parser |
| `ci/parse_branch_env.py` | Python branch mapping parser |
| `ci/README.md` | Guidance for branch mapping behavior |
| `ci/jenkins/create_seed_job.sh` | Creates/updates Jenkins seed job from config |
| `ci/jenkins/README.md` | Jenkins seed and Job DSL usage notes |
| `ci/jenkins/seed_job_pipeline.groovy` | Pipeline script for processing Job DSL seed files |
| `ci/jenkins/seed-job-config.xml` | Seed job XML template |
| `ci/jenkins/sprint4_job.groovy` | Job DSL for single-branch Sprint4 pipeline job |
| `ci/jenkins/sprint4_multibranch.groovy` | Job DSL for multibranch Sprint4 pipeline |

## G. Docs/ Files

| Path | Purpose |
|---|---|
| `Docs/ANSIBLE_ISSUES_FIXED.md` | Known Ansible issues and resolution history |
| `Docs/LOCAL_JENKINS_SETUP.md` | Local Jenkins setup instructions |
| `Docs/pipeline-usage-guide.md` | High-level usage guidance for three Jenkinsfiles |
| `Docs/QUICK_START.md` | Fast-start setup instructions |
| `Docs/SPRINT3_SETUP_GUIDE.md` | Sprint 3-specific setup guidance |
| `Docs/TERRAFORM_ISSUES_FIXED.md` | Known Terraform issues and fixes |
| `Docs/defect/pipeline-eks-existing-fix/README.md` | Defect record for EKS existing-resource pipeline fix |
| `Docs/sprint4-handover/README.md` | Handover package overview |
| `Docs/sprint4-handover/01-repository-file-catalog.md` | This inventory document |
| `Docs/sprint4-handover/02-configuration-reference.md` | Consolidated config reference |
| `Docs/sprint4-handover/03-operations-commands.md` | Command runbook |
| `Docs/sprint4-handover/04-support-runbook.md` | Incident/support runbook |
| `Docs/sprint4-handover/05-execution-flow-diagrams.md` | Execution flow and sequence diagrams for delivery operations |

## H. k8s/ Files

| Path | Purpose |
|---|---|
| `k8s/deployment.yaml` | Application Deployment spec with image placeholder replacement |
| `k8s/hpa.yaml` | Horizontal Pod Autoscaler definition |
| `k8s/namespace.yaml` | Namespace resource definition |
| `k8s/service.yaml` | Service exposure (LoadBalancer/ClusterIP as configured) |

## I. scripts/ Files

| Path | Purpose |
|---|---|
| `scripts/attach-jenkins-terraform-policy.sh` | Attach IAM policy for Jenkins Terraform permissions |
| `scripts/check_post_deploy.sh` | Post-deployment validation helper |
| `scripts/create-terraform-backend.sh` | Creates S3 bucket and DynamoDB lock table for Terraform backend |
| `scripts/ensure_ansible.sh` | Ensures Ansible availability/version in runtime |
| `scripts/generate_ansible_inventory.py` | Generates inventory from Terraform JSON outputs |

## J. terraform/ Files

| Path | Purpose |
|---|---|
| `terraform/backend.tf` | Terraform backend definition |
| `terraform/main.tf` | Core AWS resource definitions |
| `terraform/outputs.tf` | Terraform outputs consumed by pipelines/scripts |
| `terraform/provider.tf` | Provider and auth configuration |
| `terraform/terraform.tfvars.example` | Example variable values |
| `terraform/tfplan` | Generated Terraform plan artifact |
| `terraform/variables.tf` | Input variable definitions and defaults |
| `terraform/versions.tf` | Terraform/provider version constraints |
