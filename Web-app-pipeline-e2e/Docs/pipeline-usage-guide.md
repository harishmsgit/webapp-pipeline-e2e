# Jenkinsfile Usage Guide

This repository includes three Jenkins pipelines, each for a different stage of the DevOps flow.

## At a Glance

| Jenkinsfile | Purpose | Typical Trigger | Main Output | Production Fit |
|---|---|---|---|---|
| `Jenkinsfile.terraform` | Provision AWS infrastructure | New environment, infra change, scaling change | Terraform-applied AWS resources | Yes, with approval and state controls |
| `Jenkinsfile.ansible` | Configure existing hosts | After infra provisioning or host change | Configured EC2/management hosts | Yes, with inventory and idempotency checks |
| `Jenkinsfile.sprint4` | Build and deploy application | App code change or release promotion | Docker image in ECR and app deployed to EKS | Yes, with scanning and rollout checks |

## Recommended Flow

1. Use `Jenkinsfile.terraform` when you need to create or change infrastructure.
2. Use `Jenkinsfile.ansible` when the infrastructure exists and needs host/tool configuration.
3. Use `Jenkinsfile.sprint4` when the app is ready to be built, packaged, pushed, and deployed.

## Jenkinsfile.terraform
Use this when you need to provision or update AWS infrastructure with Terraform.

Typical use cases:
- Create or update VPC, subnets, EKS, EC2, or state backend resources
- Run `terraform plan` and `terraform apply`
- Bootstrap the platform before application deployment

Needs:
- AWS credentials or IAM role access
- Remote Terraform state backend
- Change approval for production environments

Best practice:
- Keep it isolated from app delivery so infrastructure changes stay auditable.

## Jenkinsfile.ansible
Use this when infrastructure already exists and you need to configure servers or tools with Ansible.

Typical use cases:
- Install Docker, kubectl, AWS CLI, or other host dependencies
- Apply configuration management tasks to EC2 instances or management hosts
- Prepare a machine after Terraform provisioning

Needs:
- Ansible inventory or generated host list
- SSH or instance profile access to target hosts
- Idempotent playbooks so repeated runs stay safe

Best practice:
- Use this for host setup and drift correction, not for app builds.

## Jenkinsfile.sprint4
Use this for application delivery to Kubernetes on AWS EKS.

Typical use cases:
- Build and test the Node.js application
- Build a Docker image
- Push the image to Amazon ECR
- Deploy the app to EKS with Kubernetes manifests

Needs:
- Docker-enabled Jenkins agent
- AWS credentials with ECR and EKS permissions
- Kubernetes manifests in `k8s/`
- A stable deployment namespace and cluster target

Best practice:
- Use immutable image tags and rollout verification so deployments are traceable and repeatable.

## Simple Rule
- Terraform provisions infrastructure
- Ansible configures machines
- Sprint 4 delivers the application

## Recommended Order
1. Run `Jenkinsfile.terraform` first to create the AWS foundation.
2. Run `Jenkinsfile.ansible` next if you need host or tool configuration.
3. Run `Jenkinsfile.sprint4` last to build, push, and deploy the app.

## Is This Production Ready?

Yes, the separation is a real-world pattern. It becomes production-ready when you also add:

- credential isolation per pipeline
- approval gates for infrastructure and production deploys
- image scanning and policy checks
- rollback and version pinning
- Jenkins shared libraries for common logic
- job audit logs and retention policies

If you want a single sentence rule: use separate Jenkinsfiles when the work has different owners, different credentials, or different risk levels.
