# Quick Reference - Deployment & Validation

## Pre-Deployment Checklist

- [ ] AWS credentials configured in Jenkins agent
- [ ] S3 bucket `harish-terraform-state-bucket` exists in `ap-south-1`
- [ ] DynamoDB table `my-terraform-lock-table` exists (with LockID partition key)
- [ ] ECR repository created (if using CodeBuild)
- [ ] IAM permissions allow EKS, ECR, S3, DynamoDB operations
- [ ] Git repository connected to Jenkins

## Deployment Steps

### Step 1: Initialize Terraform Backend
```bash
cd terraform

# Review backend configuration
cat backend.tf

# Initialize backend (creates .terraform directory, downloads providers)
terraform init -reconfigure
```

**Expected Output:**
```
Initializing the backend...
Initializing provider plugins...
- hashicorp/aws v5.100.0
- hashicorp/kubernetes v2.38.0
- hashicorp/helm v2.17.0
Terraform has been successfully configured!
```

### Step 2: Validate Terraform Configuration
```bash
# Validate syntax
terraform validate

# Check formatting
terraform fmt -check
```

**Expected Output:**
```
Success! The configuration is valid.
```

### Step 3: Plan Infrastructure
```bash
# Select environment workspace
terraform workspace select dev
# or: terraform workspace new dev   (first time)

# Generate plan
terraform plan -out=tfplan
```

**Expected Output:**
```
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Plan: 50 to add, 0 to change, 0 to destroy.
```

### Step 4: Apply Infrastructure
```bash
# Apply Terraform plan (20-30 minutes for EKS cluster creation)
terraform apply tfplan
```

**Expected Output:**
```
aws_vpc.main: Creating...
aws_eks_cluster.main: Creating...  (this takes longest)
helm_release.alb_ingress_controller: Creating...
helm_release.prometheus: Creating...
...
Apply complete! Resources: 50 added, 0 changed, 0 destroyed.

Outputs:
alb_ingress_controller_status = "ALB Ingress Controller deployed in kube-system namespace"
alb_ingress_endpoint = "Run: kubectl get ingress -n demo -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'"
monitoring_stack_status = "Monitoring stack deployed in monitoring namespace..."
```

### Step 5: Verify Cluster Access
```bash
# Get cluster name from Terraform output or variables.tf
CLUSTER_NAME="dev-webapp-cluster"
REGION="ap-south-1"

# Update kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# Verify access
kubectl cluster-info
kubectl get nodes
```

### Step 6: Check Deployments
```bash
# Check all namespaces
kubectl get ns

# Check ALB Ingress Controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check demo app
kubectl get pods -n demo
kubectl get deployment -n demo

# Check HPA
kubectl get hpa -n demo

# Check monitoring stack
kubectl get pods -n monitoring
```

### Step 7: Wait for ALB Creation (2-3 minutes)
```bash
# Watch ingress status
kubectl get ingress -n demo -w

# Once ADDRESS is populated, copy it
kubectl get ingress demo-nginx-ingress -n demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Step 8: Test Application Access
```bash
# Get ALB endpoint
ALB_ENDPOINT=$(kubectl get ingress demo-nginx-ingress -n demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test HTTP access
curl http://$ALB_ENDPOINT/

# Expected: nginx 200 OK with welcome page
```

### Step 9: Access Monitoring Dashboards

**Grafana:**
```bash
# Port-forward to Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open browser
# URL: http://localhost:3000
# Login: admin / {environment}-grafana-admin
# Example: admin / dev-grafana-admin
```

**Prometheus:**
```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Open browser
# URL: http://localhost:9090
```

**CloudWatch Logs:**
```bash
# View in AWS Console or CLI
aws logs tail /aws/eks/{cluster-name}/cluster --follow

# Or in AWS Console:
# CloudWatch → Log Groups → /aws/eks/dev-webapp-cluster/cluster
```

## HPA (Horizontal Pod Autoscaler) Verification

### Check HPA Status
```bash
kubectl get hpa -n demo

# Output should show:
# NAME             REFERENCE                 TARGETS    MINPODS  MAXPODS
# demo-nginx-hpa   Deployment/demo-nginx     5%/70%     2        10
```

### View HPA Details
```bash
kubectl describe hpa demo-nginx-hpa -n demo
```

### Generate Load to Test Scaling
```bash
# Start load generator
kubectl run -n demo -it --rm load-generator --image=busybox /bin/sh

# Inside pod, run:
while true; do wget -q -O- http://demo-nginx/; done
```

### Watch Scaling in Action
```bash
# In another terminal, watch HPA
kubectl get hpa -n demo -w

# Watch pods scaling
kubectl get pods -n demo -w
```

## Destroy Infrastructure (if needed)

```bash
# WARNING: This removes all resources!
terraform destroy

# Or select specific resource
terraform destroy -target=aws_eks_cluster.main
```

## Common Issues & Solutions

### Issue 1: Backend Initialization Fails
**Error:** `Error: Invalid AWS Region: REPLACE_WITH_YOUR_AWS_REGION`

**Solution:**
```bash
# Update backend.tf with actual region
# S3 bucket ap-south-1:
terraform init -reconfigure \
  -backend-config="bucket=harish-terraform-state-bucket" \
  -backend-config="region=ap-south-1"
```

### Issue 2: ALB Not Getting External IP
**Symptom:** `<pending>` in ingress status for 5+ minutes

**Solution:**
```bash
# Check ALB controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check if subnets have ALB tags
aws ec2 describe-subnets --region {region} | grep -i alb

# Tags should include:
# "kubernetes.io/role/elb": "1"
```

### Issue 3: Metrics Not Showing in Grafana
**Symptom:** "No data" in Grafana dashboards

**Solution:**
```bash
# Check metrics-server
kubectl get deployment metrics-server -n kube-system

# Wait 2-3 minutes for metrics collection
# Then query Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Visit: http://localhost:9090
# Query: container_cpu_usage_seconds_total
```

### Issue 4: HPA Not Scaling
**Symptom:** Replicas stay at minReplicas even under load

**Solution:**
```bash
# Check HPA status
kubectl describe hpa demo-nginx-hpa -n demo

# Check if metrics are available
kubectl get hpa demo-nginx-hpa -n demo

# Ensure pod resource requests are set (required for % calculations)
kubectl get pods -n demo -o json | grep -A 5 "resources"
```

### Issue 5: Grafana Password Incorrect
**Symptom:** Login fails with default credentials

**Solution:**
```bash
# Credentials: admin / {environment}-grafana-admin
# Examples:
# dev environment:   admin / dev-grafana-admin
# prod environment:  admin / prod-grafana-admin

# Reset if needed:
kubectl exec -n monitoring {grafana-pod} -- grafana-cli admin reset-admin-password newpassword
```

## Validation Checklist

After deployment, verify:

- [ ] **Cluster**: `kubectl get nodes` shows at least 1 node
- [ ] **ALB Controller**: `kubectl get pods -n kube-system` shows aws-load-balancer-controller running
- [ ] **Demo App**: `kubectl get deployment -n demo` shows demo-nginx with 2+ replicas
- [ ] **HPA**: `kubectl get hpa -n demo` shows scaling configured
- [ ] **Ingress**: `kubectl get ingress -n demo` shows ALB endpoint populated
- [ ] **App Access**: `curl http://{ALB_ENDPOINT}/` returns 200 OK
- [ ] **Prometheus**: Port-forward works, can scrape metrics
- [ ] **Grafana**: Can login and view dashboards
- [ ] **CloudWatch**: Logs appear in `/aws/eks/{cluster}/cluster` log group
- [ ] **Terraform State**: S3 object exists: `s3://harish-terraform-state-bucket/terraform/terraform.tfstate`

## Environment Variables Quick Reference

```bash
# Terraform
export TF_VAR_aws_region="ap-south-1"
export TF_VAR_environment="dev"

# AWS
export AWS_REGION="ap-south-1"
export AWS_PROFILE="default"  # or your profile

# Jenkins Parameters (set in UI)
AWS_REGION=ap-south-1
TF_STATE_BUCKET=harish-terraform-state-bucket
LOCK_TABLE=my-terraform-lock-table
ENVIRONMENT=dev
ECR_REGISTRY=123456789.dkr.ecr.ap-south-1.amazonaws.com
ECR_REPOSITORY=webapp
BUILD_AND_PUSH_IMAGE=true
```

## Useful Commands

```bash
# Get cluster info
kubectl cluster-info

# Get all resources
kubectl get all --all-namespaces

# Port-forward to service
kubectl port-forward -n {namespace} svc/{service-name} {local}:{remote}

# Tail pod logs
kubectl logs -f -n {namespace} deployment/{deployment-name}

# Exec into pod
kubectl exec -it -n {namespace} {pod-name} -- /bin/sh

# Scale deployment
kubectl scale deployment {name} --replicas={count} -n {namespace}

# Watch resource changes
kubectl get {resource} -n {namespace} -w

# Terraform
terraform workspace list
terraform workspace select {name}
terraform plan -destroy  # preview destruction
terraform fmt           # format files
terraform validate      # validate syntax
```

---

**Status**: Ready for deployment  
**Last Updated**: June 2026  
**Expected Deployment Time**: 20-30 minutes (mainly EKS cluster creation)
