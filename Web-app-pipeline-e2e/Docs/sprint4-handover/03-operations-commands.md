# Operations Command Runbook

This section provides practical command sets for support and handover operations.

## 1. Local Repository and Build Commands

```bash
# clone and enter repo
git clone <repo-url>
cd Web-app-pipeline-e2e

# verify app
cd app
npm ci
npm test
npm start
```

```bash
# build app image manually
cd app
docker build -t web-app-sprint4:local -f Dockerfile .
```

## 2. AWS Identity and Environment Commands

```bash
# verify caller identity
aws sts get-caller-identity --region ap-south-1

# set reusable environment variables
export AWS_REGION=ap-south-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REPO_NAME=web-app-sprint4
export EKS_CLUSTER_NAME=java-spring-eks
export K8S_NAMESPACE=webapp
```

## 3. ECR Commands

```bash
# login to ECR
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# ensure repository exists
aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" || \
aws ecr create-repository --repository-name "$ECR_REPO_NAME" --region "$AWS_REGION"

# push image
IMAGE_TAG=test-$(date +%Y%m%d%H%M%S)
IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG"
docker tag web-app-sprint4:local "$IMAGE_URI"
docker push "$IMAGE_URI"
```

## 4. EKS and Kubernetes Commands

```bash
# configure kubectl context for EKS
aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"

# ensure namespace and deploy manifests
kubectl create namespace "$K8S_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# deploy with image substitution
sed "s|REPLACE_IMAGE|$IMAGE_URI|g" k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml

# rollout and health checks
kubectl rollout status deployment/webapp -n "$K8S_NAMESPACE" --timeout=300s
kubectl get all -n "$K8S_NAMESPACE"
kubectl get hpa -n "$K8S_NAMESPACE"
```

## 5. Terraform Commands

```bash
cd terraform

# backend init
terraform init -reconfigure \
  -backend-config="bucket=harish-terraform-state-bucket" \
  -backend-config="key=terraform/terraform.tfstate" \
  -backend-config="region=ap-south-1" \
  -backend-config="use_lockfile=true" \
  -backend-config="dynamodb_table=my-terraform-lock-table"

# workspace and lifecycle
terraform workspace select -or-create dev
terraform validate
terraform plan -out=tfplan
terraform apply -auto-approve tfplan
terraform output -json > ../ansible/terraform-outputs.json
```

## 6. Terraform Backend Creation Script

```bash
# from repo root
./scripts/create-terraform-backend.sh harish-terraform-state-bucket my-terraform-lock-table ap-south-1
```

## 7. Ansible Commands

```bash
# ensure ansible runtime dependencies
./scripts/ensure_ansible.sh

# generate inventory from terraform output
python3 scripts/generate_ansible_inventory.py \
  --terraform-output ansible/terraform-outputs.json \
  --inventory ansible/inventories/generated/hosts.ini \
  --remote-user ubuntu

# configure and validate management host
ansible-playbook -i ansible/inventories/generated/hosts.ini ansible/playbooks/configure-management.yml
ansible-playbook -i ansible/inventories/generated/hosts.ini ansible/playbooks/validate-management.yml
```

## 8. Jenkins Seed Job and DSL Commands

```bash
# example Jenkins trigger from CLI
curl -X POST "<JENKINS_URL>/job/seed-job/build" --user "<user>:<api_token>"
curl -X POST "<JENKINS_URL>/job/webapp-sprint4-pipeline/build" --user "<user>:<api_token>"
```

```bash
# seed job creation helper
cd ci/jenkins
bash create_seed_job.sh
```

## 9. Recommended Pipeline Execution Order

1. Run Terraform pipeline (`Jenkinsfile.terraform`)
2. Run Ansible pipeline (`Jenkinsfile.ansible`)
3. Run Sprint4 delivery pipeline (`Jenkinsfile.sprint4`)

## 10. Quick Diagnostics Commands

```bash
# image present locally
docker images | grep web-app-sprint4

# image exists in ECR
aws ecr describe-images --repository-name "$ECR_REPO_NAME" --image-ids imageTag="$IMAGE_TAG" --region "$AWS_REGION"

# check deployment events
kubectl describe deployment webapp -n "$K8S_NAMESPACE"
kubectl get events -n "$K8S_NAMESPACE" --sort-by=.metadata.creationTimestamp

# check pod logs
kubectl logs -n "$K8S_NAMESPACE" deployment/webapp --tail=200
```
