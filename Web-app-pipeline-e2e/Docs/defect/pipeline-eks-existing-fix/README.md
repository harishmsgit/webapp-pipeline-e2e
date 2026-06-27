# Defect: Terraform pipeline fails on existing EKS CloudWatch log group

## Issue Description

The Jenkins Terraform pipeline reached the `Terraform Apply` stage and failed with:

```text
Error: creating CloudWatch Logs Log Group (/aws/eks/webapp-eks-cluster/cluster):
ResourceAlreadyExistsException: The specified log group already exists
```

The AWS credentials problem was already resolved. The failure happened because the CloudWatch log group already exists in AWS, but Terraform state does not currently manage it at:

```text
aws_cloudwatch_log_group.eks_cluster
```

Terraform therefore attempted to create the log group again during `terraform apply`, and AWS rejected the request because the resource name already exists.

## Impact

- Terraform apply fails at the end of the pipeline.
- Some earlier resources may already be created or modified before the failure.
- Jenkins reports the pipeline as failed with `script returned exit code 1`.

## Resolution

Import the existing CloudWatch log group into the same Terraform state and workspace used by Jenkins.

Run this on the Jenkins server as the `jenkins` user, or from another machine that has Terraform, AWS credentials, and access to the same S3 backend:

```bash
cd /var/lib/jenkins/workspace/webapp-pipeline-terraform-dev/Web-app-pipeline-e2e/terraform

terraform init -reconfigure \
  -backend-config="bucket=harish-terraform-state-bucket" \
  -backend-config="key=terraform/terraform.tfstate" \
  -backend-config="region=ap-south-1" \
  -backend-config="use_lockfile=true" \
  -backend-config="dynamodb_table=my-terraform-lock-table"

terraform workspace select dev

terraform import aws_cloudwatch_log_group.eks_cluster /aws/eks/webapp-eks-cluster/cluster
```

After the import succeeds, rerun the Jenkins pipeline.

## Verification

Confirm Terraform now recognizes the log group:

```bash
terraform state show aws_cloudwatch_log_group.eks_cluster
terraform plan
```

Expected result:

- The CloudWatch log group should no longer be planned for creation.
- The Jenkins pipeline should proceed past the previous failure point.

