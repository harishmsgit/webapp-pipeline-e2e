# Modern Web App Pipeline - Architecture Documentation

## Overview

This project implements a **modern, production-ready architecture** for deploying containerized web applications on AWS EKS with CI/CD automation, monitoring, and auto-scaling.

### Architecture Components

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        SOURCE CODE REPOSITORY                           │
│                         (GitHub/GitLab)                                 │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                        CI/CD PIPELINE (JENKINS)                         │
├─────────────────────────────────────────────────────────────────────────┤
│ 1. Checkout source code                                                 │
│ 2. Build & Push Docker Image (CodeBuild or local Docker)               │
│ 3. Push image to Amazon ECR (Elastic Container Registry)              │
│ 4. Validate AWS credentials                                            │
│ 5. Prepare Terraform backend (S3 + DynamoDB)                          │
│ 6. Terraform validate & plan                                           │
│ 7. Terraform apply (provision infrastructure)                         │
│ 8. Workspace selection (branch-based: main→prod, dev→dev)             │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                     AWS CLOUD INFRASTRUCTURE                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  AWS Region (ap-south-1)                                             │
│  ├─ VPC (Virtual Private Cloud)                                       │
│  │   └─ Public Subnets (2x) with NAT/IGW                             │
│  │                                                                     │
│  ├─ EC2 Management Instance                                          │
│  │   └─ For cluster admin access (kubectl, helm, aws cli)            │
│  │                                                                     │
│  ├─ Amazon EKS Cluster                                               │
│  │   ├─ Control Plane (AWS managed)                                  │
│  │   │   └─ API, Scheduler, Controller Manager, Etcd                │
│  │   │   └─ CloudWatch Logs enabled (7 day retention)               │
│  │   │                                                                │
│  │   ├─ Node Group (EC2 instances)                                   │
│  │   │   └─ 1 node (t3.medium) → scale via HPA                      │
│  │   │   └─ Auto-scaling group managed by EKS                       │
│  │   │                                                                │
│  │   ├─ ALB Ingress Controller (AWS Load Balancer Controller)        │
│  │   │   ├─ Deployed via Helm chart (v2.6.2)                        │
│  │   │   ├─ IRSA: IAM role via OIDC provider                        │
│  │   │   └─ Creates AWS ALBs for Kubernetes Ingress resources      │
│  │   │                                                                │
│  │   ├─ Kubernetes Namespaces                                        │
│  │   │   ├─ demo (demo nginx application)                           │
│  │   │   │   ├─ Deployment (nginx:stable, replicas: 2-10)          │
│  │   │   │   ├─ Service (ClusterIP)                                │
│  │   │   │   ├─ HPA (70% CPU target, min 2, max 10)                │
│  │   │   │   └─ Ingress (ALB annotations)                          │
│  │   │   │                                                           │
│  │   │   ├─ monitoring (observability stack)                         │
│  │   │   │   ├─ Prometheus (metrics scraping)                       │
│  │   │   │   ├─ Grafana (dashboards, admin pass: env-grafana-admin) │
│  │   │   │   ├─ AlertManager (alerting)                            │
│  │   │   │   └─ node-exporter (node metrics)                       │
│  │   │   │                                                           │
│  │   │   └─ kube-system (AWS-managed)                              │
│  │   │       └─ ALB Ingress Controller                             │
│  │   │                                                              │
│  │   └─ Auto-scaling                                               │
│  │       └─ Metrics Server (provides CPU/memory metrics)           │
│  │       └─ HPA controller (adjusts replicas based on metrics)    │
│  │                                                                 │
│  └─ Amazon ECR (Elastic Container Registry)                        │
│      └─ Docker image repository for application                   │
│                                                                     │
│  └─ S3 Bucket (Terraform State)                                   │
│      └─ State locking via DynamoDB table                         │
│                                                                     │
│  └─ AWS ALB (Application Load Balancer)                          │
│      └─ Auto-created by ALB Ingress Controller                   │
│      └─ Routes traffic to demo-nginx service                    │
│                                                                     │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                     APPLICATION ACCESS LAYER                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  AWS ALB (Internet-facing)                                            │
│  │                                                                     │
│  ├─→ Kubernetes Ingress (ALB-managed)                                │
│  │   └─ Route: "/" → demo-nginx service                            │
│  │                                                                   │
│  └─→ demo-nginx Service (ClusterIP)                                 │
│      ├─→ Pod 1 (nginx:stable)                                      │
│      ├─→ Pod 2 (nginx:stable)                                      │
│      └─→ Pod N (auto-scaled based on CPU)                         │
│                                                                     │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                    MONITORING & OBSERVABILITY                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─ CloudWatch Logs                                                   │
│  │  └─ EKS cluster logs: api, audit, authenticator, etc.            │
│  │  └─ Log Group: /aws/eks/{cluster-name}/cluster                  │
│  │  └─ 7-day retention                                              │
│  │                                                                   │
│  ├─ Prometheus (Metrics Collection)                                  │
│  │  ├─ Scrapes kubelet, kube-proxy, kube-state-metrics             │
│  │  ├─ Stores time-series metrics data                             │
│  │  ├─ 1Gi storage volume                                          │
│  │  └─ Accessible via port-forward                                │
│  │                                                                  │
│  ├─ Grafana (Visualization & Dashboards)                           │
│  │  ├─ Pre-built dashboards for Kubernetes                        │
│  │  ├─ Node exporter metrics (CPU, memory, disk)                 │
│  │  ├─ Pod metrics (resource usage)                              │
│  │  ├─ Access: localhost:3000 (via port-forward)                │
│  │  └─ Admin: admin / {env}-grafana-admin                       │
│  │                                                                 │
│  └─ AlertManager (Alerting)                                       │
│     └─ Rule-based alerts from Prometheus data                   │
│                                                                   │
│  Access Grafana:                                                  │
│  $ kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
│  → Open browser: http://localhost:3000                          │
│                                                                   │
│  View CloudWatch Logs:                                           │
│  → AWS Console > CloudWatch > Log Groups                         │
│  → /aws/eks/{cluster-name}/cluster                             │
│                                                                   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Key Technologies & Versions

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **IaC** | Terraform | >= 1.5.0 | Infrastructure provisioning & state management |
| **Cloud** | AWS | - | Primary cloud provider |
| **Compute** | Amazon EKS | Latest | Managed Kubernetes service |
| **Container Registry** | Amazon ECR | - | Secure image repository |
| **Load Balancer** | AWS ALB | - | Application load balancing (native AWS) |
| **Networking** | VPC | - | Isolated network with subnets |
| **Monitoring** | Prometheus | Latest | Metrics collection & alerting |
| **Visualization** | Grafana | Latest | Metrics visualization & dashboards |
| **Ingress Controller** | AWS LB Controller | 2.6.2 | Kubernetes Ingress → AWS ALB mapping |
| **Demo App** | nginx | stable | Sample application |
| **Scaling** | HPA | Kubernetes native | Horizontal pod autoscaling |
| **Container Builder** | AWS CodeBuild | - | Docker image builds (isolated) |
| **State Backend** | S3 + DynamoDB | - | Terraform state locking & storage |

## Deployment Flow

### 1. Source Code Commit
```bash
git push origin develop  # or main, qa, feature branch
```

### 2. Jenkins Pipeline Triggers
```groovy
Pipeline: Jenkinsfile.terraform
├─ Checkout code
├─ Build Docker image (CodeBuild or local)
├─ Push to ECR
├─ Validate AWS access
├─ Create S3/DynamoDB backend (if needed)
├─ Terraform init
├─ Select workspace (develop → dev, main → prod)
├─ Terraform plan
└─ Terraform apply
```

### 3. Infrastructure Provisioning
```bash
terraform apply
├─ VPC, Subnets, Security Groups
├─ EKS Cluster & Node Group
├─ IAM roles & OIDC provider
├─ ALB Ingress Controller (Helm)
├─ Demo application & HPA
├─ Prometheus & Grafana
└─ CloudWatch logging
```

### 4. Application Access
```bash
# Get ALB endpoint (wait 2-3 minutes)
kubectl get ingress -n demo

# Access demo app
curl http://{ALB_ENDPOINT}/

# Monitor via Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open: http://localhost:3000
# Login: admin / {env}-grafana-admin
```

## Environment Management

### Branch-to-Environment Mapping

| Git Branch | Terraform Workspace | Environment | ECR Tag |
|-----------|-------------------|-------------|---------|
| `main` or `master` | `prod` | production | `latest`, `v{BUILD}` |
| `develop` or `dev` | `dev` | development | `dev-{BUILD}` |
| `qa` or `staging` | `qa` | QA testing | `qa-{BUILD}` |
| `feature/*` | sanitized branch name | feature env | `feature-{BUILD}` |

### Multi-Environment Support

Each environment has:
- Separate Terraform workspace (isolated state)
- Isolated S3 state bucket path: `env:/{workspace}/terraform.tfstate`
- DynamoDB locking per workspace
- Separate EKS clusters (optional)
- Environment-specific variable overrides

## Configuration Files

### Backend Configuration (`terraform/backend.tf`)
```hcl
terraform {
  backend "s3" {
    bucket         = "harish-terraform-state-bucket"
    key            = "terraform/terraform.tfstate"
    region         = "ap-south-1"        # Update to match bucket region
    use_lockfile   = true              # Modern locking (no DynamoDB deprecated warning)
    encrypt        = true
  }
}
```

### Terraform Variables (`terraform/variables.tf`)
```hcl
variable "aws_region" {
  default = "ap-south-1"              # Change for different region
}

variable "environment" {
  default = null                      # Optional - fallback to workspace name
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "cluster_name" {
  default = "dev-webapp-cluster"
}
```

### Jenkins Pipeline Parameters (`Jenkinsfile.terraform`)
```groovy
parameters {
  string(name: 'AWS_REGION', defaultValue: 'ap-south-1', ...)
  string(name: 'TF_STATE_BUCKET', defaultValue: 'harish-terraform-state-bucket', ...)
  string(name: 'ENVIRONMENT', defaultValue: 'dev', ...)
  string(name: 'ECR_REGISTRY', defaultValue: '', ...)        // Required for CodeBuild
  string(name: 'ECR_REPOSITORY', defaultValue: 'webapp', ...)
  string(name: 'CODEBUILD_PROJECT', defaultValue: '', ...)   // Optional CodeBuild integration
  booleanParam(name: 'BUILD_AND_PUSH_IMAGE', defaultValue: false, ...)
}
```

## AWS Resources Created

### Compute
- **EKS Cluster**: Managed Kubernetes control plane
- **Node Group**: 1 EC2 instance (t3.medium, auto-scalable)
- **ALB**: Application Load Balancer (auto-created by Ingress Controller)

### Networking
- **VPC**: Custom VPC with 2 public subnets
- **Internet Gateway**: Outbound/inbound internet access
- **Route Table**: Public routing to IGW
- **Security Groups**: EKS cluster and EC2 management rules

### Storage
- **S3 Bucket**: Terraform state (`harish-terraform-state-bucket`)
- **DynamoDB Table**: State locking

### Identity & Access
- **IAM Roles**: EKS cluster, node group, ALB controller, EC2 instance
- **OIDC Provider**: Kubernetes ↔ AWS IAM trust relationship
- **Service Accounts**: IRSA (IAM Roles for Service Accounts)

### Logging & Monitoring
- **CloudWatch Log Group**: `/aws/eks/{cluster-name}/cluster`
- **Prometheus**: Metrics collection (1Gi storage)
- **Grafana**: Visualization & dashboards
- **ECR**: Docker image registry

## Operations Guide

### 1. Initialize Terraform Backend
```bash
cd terraform

# Verify backend configuration
cat backend.tf

# Initialize (first time)
terraform init

# Note: S3 bucket must exist and be in the correct region
```

### 2. Plan & Apply Infrastructure
```bash
# Select workspace
terraform workspace select dev    # or prod, qa

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### 3. Access Kubernetes Cluster
```bash
# Update kubeconfig
aws eks update-kubeconfig --name {cluster-name} --region {region}

# Verify cluster access
kubectl get nodes
kubectl get pods --all-namespaces
```

### 4. Monitor Application
```bash
# Check demo app deployment
kubectl get deployments -n demo
kubectl get pods -n demo
kubectl get hpa -n demo

# View HPA status
kubectl describe hpa demo-nginx-hpa -n demo

# Check ALB ingress
kubectl get ingress -n demo
kubectl describe ingress demo-nginx-ingress -n demo
```

### 5. Access Monitoring Stack
```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Login: admin / {env}-grafana-admin

# AlertManager
kubectl port-forward -n monitoring svc/prometheus-kube-prom-alertmanager 9093:9093
```

### 6. Scale Demo Application
```bash
# Manual scale (overrides HPA)
kubectl scale deployment demo-nginx --replicas=5 -n demo

# HPA will adjust based on CPU metrics
kubectl get hpa demo-nginx-hpa -n demo -w
```

### 7. View Logs
```bash
# Pod logs
kubectl logs -f deployment/demo-nginx -n demo

# CloudWatch logs
aws logs tail /aws/eks/{cluster-name}/cluster --follow --region {region}
```

### 8. Destroy Infrastructure
```bash
terraform destroy  # Careful! This removes all resources
```

## Modern Architecture Patterns Implemented

### ✅ Infrastructure as Code (IaC)
- Terraform for complete AWS infrastructure automation
- State management with S3 + DynamoDB
- Workspace-based multi-environment support
- Version-controlled infrastructure changes

### ✅ Container & CI/CD Best Practices
- AWS CodeBuild for isolated, secure Docker builds
- Amazon ECR for centralized image registry
- Jenkins pipeline with automated validation & deployment
- Branch-based environment mapping (GitOps pattern)

### ✅ Kubernetes & Container Orchestration
- Amazon EKS (managed Kubernetes) for operational simplicity
- Helm charts for declarative application deployment
- RBAC & IRSA for pod-level IAM permissions
- Namespace isolation (demo, monitoring, kube-system)

### ✅ Load Balancing & Networking
- AWS ALB Ingress Controller (native AWS, no external NGINX)
- Internet-facing load balancer with auto health checks
- Security group-based traffic management
- VPC with proper subnet isolation

### ✅ Auto-Scaling & High Availability
- HPA (Horizontal Pod Autoscaler) for elastic scaling
- Metrics-based scaling decisions (CPU utilization)
- Multi-pod deployment for redundancy
- EKS managed control plane for reliability

### ✅ Observability & Monitoring
- **Logs**: CloudWatch for cluster-level events
- **Metrics**: Prometheus for collection & querying
- **Visualization**: Grafana for dashboards & alerts
- **Alerting**: AlertManager for rule-based notifications

### ✅ Security Best Practices
- IRSA: Pod-level IAM roles (no shared node credentials)
- OIDC provider: Secure Kubernetes ↔ AWS trust
- Security groups: Fine-grained network access control
- State encryption: S3-encrypted Terraform state

## Troubleshooting

### ALB Ingress Takes 2-3 Minutes
- ALB Ingress Controller creates AWS ALB asynchronously
- Check controller logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`

### HPA Not Scaling
- Ensure metrics-server is running: `kubectl get deployment -n kube-system -l k8s-app=metrics-server`
- Pod requests must be set (HPA needs CPU target % reference)
- Wait 1-2 minutes for metrics to initialize

### Terraform Backend Error
- Verify S3 bucket exists in correct region
- Check IAM permissions for S3 & DynamoDB
- DynamoDB table should have `LockID` partition key

### Grafana Not Accessible
- Port-forward: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`
- Default credentials: admin / {env}-grafana-admin
- Check pod status: `kubectl get pods -n monitoring`

### ECR Push Failed
- Verify ECR repository exists
- Check AWS credentials in Jenkins agent
- Ensure Docker is installed (if using local build)

## Next Steps

1. **Update Backend**: Configure S3 bucket in ap-south-1 region
2. **Run Terraform**: `terraform init → terraform plan → terraform apply`
3. **Configure ECR**: Create ECR repo, provide registry URL to Jenkins
4. **Setup CodeBuild** (Optional): For isolated Docker builds
5. **Test Deployment**: Trigger Jenkins pipeline from Git branch
6. **Monitor**: Access Grafana and CloudWatch dashboards
7. **Scale & Optimize**: Adjust HPA, monitor metrics, optimize costs

---

**Last Updated**: June 2026  
**Terraform Version**: >= 1.5.0  
**Kubernetes Version**: Latest EKS (auto-updated by AWS)  
**Architecture Pattern**: Modern, Cloud-Native, GitOps-Ready
