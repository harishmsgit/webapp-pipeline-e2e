# Support Runbook (Operations and Handover)

## 1. Support Ownership Model

- Platform/IaC support: Terraform resources, backend state, AWS infra drift
- Configuration support: Ansible inventory, SSH access, host package/tool states
- Release support: Sprint4 pipeline, Docker build/push, EKS deployment outcomes
- Security support: IAM policies, credential rotation, least-privilege controls

## 2. Incident Triage Entry Checklist

When a pipeline/build incident is reported:
1. Identify failing pipeline file (`Jenkinsfile.terraform`, `Jenkinsfile.ansible`, `Jenkinsfile.sprint4`)
2. Capture Jenkins build number and failing stage
3. Record current branch/commit SHA
4. Capture exact command error and exit code
5. Validate credentials used in that pipeline run

## 3. Common Failure Patterns and Responses

### 3.1 Terraform Failures
Symptoms:
- backend init failure
- lock table errors
- workspace not found

Immediate checks:
- S3 bucket exists and region is correct
- DynamoDB lock table exists
- workspace name matches environment mapping
- AWS credentials can call `sts get-caller-identity`

### 3.2 Ansible Failures
Symptoms:
- SSH unreachable
- host inventory missing/incorrect
- package install tasks failing

Immediate checks:
- generated inventory file contains reachable public IP
- SSH key credential ID and remote user are valid
- security groups allow TCP/22 from Jenkins runner source

### 3.3 Sprint4 Delivery Failures
Symptoms:
- app test failures
- ECR login/push failures
- EKS deployment or kubectl errors

Immediate checks:
- `npm test` local pass in `app/`
- ECR auth and repo existence
- image URI/tag resolved correctly
- `aws eks update-kubeconfig` success
- namespace exists and rollout status succeeds

## 4. Rollback Strategy

### 4.1 Application Rollback (Preferred)
Use a previously successful image tag:

```bash
export ROLLBACK_IMAGE_URI="<account>.dkr.ecr.<region>.amazonaws.com/web-app-sprint4:<known-good-tag>"
sed "s|REPLACE_IMAGE|$ROLLBACK_IMAGE_URI|g" k8s/deployment.yaml | kubectl apply -f -
kubectl rollout status deployment/webapp -n webapp --timeout=300s
```

### 4.2 Infrastructure Rollback
- restore from Terraform state history/backups
- run targeted plan/apply with reviewed changes
- avoid manual drift unless emergency break-glass is approved

## 5. Security and Compliance Controls

Mandatory controls for enterprise support:
- no static secrets in repository
- Jenkins credentials store for AWS and SSH keys
- IAM least-privilege with periodic review
- protected branches and mandatory review for Jenkinsfile changes
- artifact and build log retention policy

## 6. Change Management Rules

1. Any pipeline change must include:
- reason
- impacted stages
- rollback plan
- evidence from dry run or lower environment

2. Any infrastructure change must include:
- Terraform plan output review
- explicit approval before apply in production

3. Any credential-related change must include:
- rotation ticket
- post-change smoke validation

## 7. Support Handover Operating Procedure

At shift/project handover:
1. share latest successful build numbers for each pipeline
2. share current Terraform workspace and state backend details
3. share current EKS cluster/namespace/image tag in production
4. share open defects and mitigations from `Docs/defect/`
5. attach this handover package and last 7 days incident summary

## 8. Minimum Monthly Validation Tasks

- validate Jenkins credentials are active
- validate Terraform backend bucket and lock table health
- rerun Ansible validation playbook
- run Sprint4 pipeline with deployment verification
- verify ECR image scanning posture and old image cleanup policy

## 9. Escalation Triggers

Escalate to platform/security owners when:
- AWS account-level permission changes are required
- Terraform state is corrupted or lock is orphaned repeatedly
- EKS control plane/network reachability issues persist
- security-sensitive credentials are exposed or suspected compromised
