# Sprint 2 Setup Guide: AWS Infrastructure Provisioning with Terraform and Jenkins

## Objective
Automate AWS infrastructure provisioning using Terraform, with state stored in S3 and locking through DynamoDB. Configure Jenkins to run the Terraform pipeline and provision reproducible AWS environments.

## What this Sprint adds
- Terraform scripts to provision:
  - AWS VPC and public subnets
  - Internet Gateway and public route table
  - Security groups for EKS and EC2 management
  - AWS EKS cluster and managed node group
  - EC2 instance for infrastructure management
- S3 bucket and DynamoDB table for Terraform state management
- Jenkins pipeline definition in `Jenkinsfile.terraform`
- Instructions for secure, repeatable provisioning

## Prerequisites
- Jenkins agent with Terraform, AWS CLI, and access to AWS credentials
- IAM permissions for:
  - IAM role creation and attachment
  - EKS, EC2, VPC, S3, DynamoDB
  - STS access to verify identity
- AWS CLI configured or IAM instance profile attached
- Jenkins EC2 instance role should include the policy defined in `jenkins-terraform-policy.json` to allow S3 backend creation and DynamoDB locking

## Setup Steps

### 1. Create the Terraform backend resources (optional)
If you prefer to create the S3 bucket and DynamoDB table manually:

```bash
aws s3api create-bucket \
  --bucket my-terraform-state-bucket \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws dynamodb create-table \
  --table-name my-terraform-lock-table \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

### 2. Configure Jenkins Pipeline
1. Create a new Jenkins pipeline job.
2. Set the repository to this project.
3. Use `Jenkinsfile.terraform` from the `feature/sprint2-terraform` branch.
4. Configure job parameters:
   - `AWS_REGION`: `ap-south-1`
   - `TF_STATE_BUCKET`: `my-terraform-state-bucket`
   - `LOCK_TABLE`: `my-terraform-lock-table`
   - `ENVIRONMENT`: `dev`

### 3. Run the Jenkins Terraform Job
Trigger the job manually from Jenkins.

The pipeline will:
- checkout source code
- validate AWS credentials
- verify/create state backend resources
- run `terraform init`
- run `terraform validate`
- plan and apply infrastructure

### 4. Confirm Provisioning
After completion, confirm resources in AWS Console or with CLI.

```bash
aws eks describe-cluster --name webapp-eks-cluster --region ap-south-1
aws ec2 describe-instances --filters Name=tag:Name,Values=dev-webapp-management-instance --region ap-south-1
```

## Terraform Usage Locally
From the project root:

```bash
cd terraform
terraform init \
  -backend-config="bucket=my-terraform-state-bucket" \
  -backend-config="key=terraform/terraform.tfstate" \
  -backend-config="region=ap-south-1" \
  -backend-config="use_lockfile=true" \
  -backend-config="dynamodb_table=my-terraform-lock-table"

# Note
If you change backend settings, run:
```bash
terraform init -reconfigure \
  -backend-config="bucket=my-terraform-state-bucket" \
  -backend-config="key=terraform/terraform.tfstate" \
  -backend-config="region=ap-south-1" \
  -backend-config="use_lockfile=true" \
  -backend-config="dynamodb_table=my-terraform-lock-table"
```

terraform plan -out=tfplan
terraform apply -auto-approve tfplan
```

## Notes
- Update `terraform/backend.tf` placeholders if you prefer static backend configuration.
- The Jenkins job also attempts to create backend resources if they do not exist.
- Keep AWS credentials secure; use instance profiles or Jenkins credentials store.
- For a detailed Jenkins job creation walkthrough and Job DSL snippet, see `doc/jenkins-terraform-job.md`.
