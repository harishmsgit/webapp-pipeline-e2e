# Jenkins Job for Terraform Infrastructure Provisioning

This document describes how to create a Jenkins pipeline job that runs `Jenkinsfile.terraform` to provision AWS infrastructure using Terraform.

## Prerequisites

- Jenkins is installed and running.
- Jenkins agent/node has Terraform and AWS CLI installed.
- Jenkins has access to AWS credentials via IAM role or credential binding.
- The repository containing `Jenkinsfile.terraform` is available in Git.

## Create a New Pipeline Job

1. Open Jenkins and click `New Item`.
2. Enter a name like `terraform-infra-provisioning`.
3. Select `Pipeline` and click `OK`.
4. In the job configuration:
   - Under `General`, enable `GitHub project` if using GitHub.
   - Under `Build Triggers`, enable `Poll SCM` or `GitHub hook trigger for GITScm polling` if desired.
   - Under `Pipeline`, set `Definition` to `Pipeline script from SCM`.
   - Select `Git` as the SCM.
   - Set the repository URL and credentials.
   - Set `Branch Specifier` to the feature branch containing `Jenkinsfile.terraform`, e.g. `*/feature/sprint2-terraform`.
   - Set `Script Path` to `Jenkinsfile.terraform`.

## Configure Pipeline Parameters

The job uses the following parameters:

- `AWS_REGION`: AWS region for provisioning (default: `ap-south-1`).
- `TF_STATE_BUCKET`: S3 bucket name for Terraform state.
- `LOCK_TABLE`: DynamoDB table name for Terraform lock state.
- `ENVIRONMENT`: Environment identifier (`dev`, `staging`, `prod`).
- `CLUSTER_NAME`: EKS cluster name to create, or import if it already exists.

Example values:

- `AWS_REGION` = `ap-south-1`
- `TF_STATE_BUCKET` = `my-terraform-state-bucket`
- `LOCK_TABLE` = `my-terraform-lock-table`
- `ENVIRONMENT` = `dev`
- `CLUSTER_NAME` = `webapp-eks-cluster`

## Required AWS Permissions

The Jenkins agent credentials or attached instance role must allow:

- `s3:CreateBucket`, `s3:HeadBucket`, `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, `s3:ListBucket`
- `dynamodb:CreateTable`, `dynamodb:DescribeTable`, `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:DeleteItem`, `dynamodb:UpdateItem`
- `iam:CreateRole`, `iam:AttachRolePolicy`, `iam:PassRole`
- `eks:CreateCluster`, `eks:DescribeCluster`, `eks:CreateNodegroup`, `eks:DescribeNodegroup`
- `ec2:CreateSecurityGroup`, `ec2:AuthorizeSecurityGroupIngress`, `ec2:CreateTags`, `ec2:RunInstances`, `ec2:DescribeInstances`
- `vpc:CreateVpc`, `vpc:DescribeVpcs`, `vpc:CreateSubnet`, `vpc:CreateInternetGateway`, `ec2:CreateRoute`, `ec2:AssociateRouteTable`

For convenience, attach the policy defined in `jenkins-terraform-policy.json` to the Jenkins EC2 role.

## Example Job DSL Snippet

If you manage Jenkins jobs as code, use this snippet as a starting point.

```groovy
pipelineJob('terraform-infra-provisioning') {
  description('Provision AWS infrastructure using Terraform via Jenkins')
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url('https://github.com/your-org/your-repo.git')
            credentials('github-credentials-id')
          }
          branches('*/feature/sprint2-terraform')
        }
      }
      scriptPath('Jenkinsfile.terraform')
    }
  }
  parameters {
    stringParam('AWS_REGION', 'ap-south-1', 'AWS region for provisioning')
    stringParam('TF_STATE_BUCKET', 'my-terraform-state-bucket', 'S3 bucket for Terraform state')
    stringParam('LOCK_TABLE', 'my-terraform-lock-table', 'DynamoDB table for state locking')
    stringParam('ENVIRONMENT', 'dev', 'Deployment environment')
    stringParam('CLUSTER_NAME', 'webapp-eks-cluster', 'EKS cluster name to create or import')
  }
}
```

## Run the Job

1. Save the job configuration.
2. Click `Build Now`.
3. Monitor the console output for stages:
   - Checkout
   - Validate AWS Access
   - Prepare Backend
   - Terraform Init
   - Terraform Validate
   - Terraform Plan
   - Terraform Apply

## Verification

After the job completes successfully, verify key AWS resources:

```bash
aws eks describe-cluster --name webapp-eks-cluster --region ap-south-1
aws ec2 describe-instances --filters "Name=tag:Name,Values=dev-webapp-management-instance" --region ap-south-1
aws s3api head-bucket --bucket my-terraform-state-bucket --region ap-south-1
aws dynamodb describe-table --table-name my-terraform-lock-table --region ap-south-1
```
