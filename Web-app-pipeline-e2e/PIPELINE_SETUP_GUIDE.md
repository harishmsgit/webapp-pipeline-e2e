# Pipeline Setup & End-to-End Configuration Guide

## Overview

The Jenkinsfile.terraform pipeline is **well-structured and will work**, but requires proper AWS configuration and permissions. This guide provides everything you need to set up.

## Current Backend Issue ⚠️

**Problem**: `terraform init` is failing because:
- S3 bucket `harish-terraform-state-bucket` is in `ap-south-1`
- But `terraform/backend.tf` specifies `region = "ap-south-1"`

**Solution**: Update backend.tf to match the actual bucket region:

```hcl
# terraform/backend.tf
terraform {
  backend "s3" {
    bucket         = "harish-terraform-state-bucket"
    key            = "terraform/terraform.tfstate"
    region         = "ap-south-1"  # ← CHANGE THIS to ap-south-1
    use_lockfile   = true
    encrypt        = true
  }
}
```

---

## Part 1: AWS IAM Permissions Setup

### 1.1 Create IAM Role for Jenkins

Jenkins agent needs permissions to:
- Access S3 (Terraform state)
- Access DynamoDB (state locking)
- Create/manage EKS, VPC, IAM resources
- Access ECR
- Access CodeBuild

**Option A: Create Specific Policy (Recommended)**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformBackend",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "arn:aws:s3:::harish-terraform-state-bucket",
        "arn:aws:s3:::harish-terraform-state-bucket/*"
      ]
    },
    {
      "Sid": "TerraformLocking",
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:ap-south-1:*:table/my-terraform-lock-table"
    },
    {
      "Sid": "EKSManagement",
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "iam:*",
        "elasticloadbalancing:*",
        "logs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRAccess",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:GetImages",
        "ecr:CreateRepository",
        "ecr:DescribeRepositories"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CodeBuildAccess",
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Sid": "STSAccess",
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

### 1.2 Attach Policy to Jenkins

**If Jenkins runs on EC2:**
1. Create IAM role with above policy
2. Attach to EC2 instance
3. Restart Jenkins agent

**If Jenkins uses AWS credentials file:**
1. Create IAM user with above policy
2. Generate AWS access keys
3. Add to Jenkins credentials manager
4. Configure Jenkins job to use these credentials

**For Local Jenkins (Development):**
```bash
# Configure AWS CLI with credentials
aws configure

# Verify access
aws sts get-caller-identity
aws s3api head-bucket --bucket harish-terraform-state-bucket --region us-west-2
```

---

## Part 2: ECR Repository Setup

### 2.1 Create ECR Repository

```bash
# Create ECR repository
aws ecr create-repository \
  --repository-name webapp \
  --region ap-south-1 \
  --encryption-configuration encryptionType=AES

# Output: Get the repository URI
# Copy: {AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/webapp
```

### 2.2 Get ECR Registry URL

```bash
# Get your AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get ECR registry URL
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com"
echo "ECR_REGISTRY=${ECR_REGISTRY}"

# Store for Jenkins parameters
# Example: 123456789.dkr.ecr.ap-south-1.amazonaws.com
```

### 2.3 Enable ECR Pull-Through Cache (Optional)

```bash
aws ecr create-pull-through-cache-rule \
  --ecr-repository-prefix nginx \
  --upstream-repository-url docker.io \
  --region ap-south-1
```

---

## Part 3: Jenkins Configuration

### 3.1 Install Required Plugins

In Jenkins, go to **Manage Jenkins → Manage Plugins** and install:
- ✅ Pipeline (already included)
- ✅ Git (already included)
- ✅ AWS Credentials
- ✅ Docker Pipeline
- ✅ CloudBees AWS Credentials

### 3.2 Add AWS Credentials to Jenkins

#### Option A: Jenkins UI (If Jenkins is running locally or accessible via web)

1. Go to **Manage Jenkins → Manage Credentials**
2. Click **Global credentials (unrestricted)**
3. Click **Add Credentials**
4. Select: **AWS Credentials**
5. Fill in:
   - **Kind**: AWS Credentials
   - **Access Key ID**: Your AWS access key (starts with AKIA...)
   - **Secret Access Key**: Your AWS secret key (long string)
   - **ID**: `aws-credentials` (used in pipeline reference)
   - **Description**: Jenkins AWS Credentials
6. Click **Create**

#### Option B: Local Jenkins Setup with AWS Access Keys (DETAILED STEPS)

This is perfect for **local development Jenkins** (not on EC2).

**Step 1: Get AWS Access Keys**

```bash
# 1. Open AWS Console
# 2. Go to: IAM → Users → Your User → Security credentials
# 3. Create access key (or use existing)
# 4. Copy:
#    - Access Key ID: AKIAIOSFODNN7EXAMPLE
#    - Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPOkYRELKZZLZrLH81
```

**Step 2: Add Credentials to Jenkins (Web UI)**

```
1. Jenkins Home Page
2. Click: "Manage Jenkins" (left sidebar)
3. Click: "Manage Credentials"
4. Under "Global credentials (unrestricted)", click "Add Credentials"
5. From dropdown "Kind", select "AWS Credentials"
6. Fill form:
   ┌─────────────────────────────────────┐
   │ Kind: AWS Credentials               │
   │ Scope: Global                       │
   │ Access Key ID: AKIAIOSFODNN7EXAMPLE │
   │ Secret Access Key: [paste secret]   │
   │ ID: aws-credentials                 │
   │ Description: Jenkins AWS Access     │
   └─────────────────────────────────────┘
7. Click: "Create"
```

**Step 3: Verify Credentials in Jenkins**

```
1. Go to: Manage Jenkins → Manage Credentials
2. Click on "aws-credentials"
3. Should show: "AWS Credentials"
4. No error means credentials stored successfully
```

**Step 4: Use Credentials in Pipeline Job**

```groovy
// In Jenkinsfile or Jenkins job config
withAWS(credentials: 'aws-credentials', region: 'us-west-2') {
    sh 'aws sts get-caller-identity'  // Will work
}
```

---

#### Option C: Environment Variables Method (For Local Jenkins)

If you don't want to store credentials in Jenkins, use environment variables:

**Step 1: Set AWS Environment Variables**

```bash
# Windows PowerShell
$env:AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
$env:AWS_SECRET_ACCESS_KEY = "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"
$env:AWS_DEFAULT_REGION = "us-west-2"

# Verify
aws sts get-caller-identity
```

```bash
# Linux/Mac Bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="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"
export AWS_DEFAULT_REGION="ap-south-1"

# Verify
aws sts get-caller-identity
```

**Step 2: Restart Jenkins**

```bash
# Windows
net stop Jenkins
net start Jenkins

# Linux
sudo systemctl restart jenkins

# Docker
docker restart jenkins
```

**Step 3: Jenkins Will Use Environment Variables**

- No need to add credentials in Jenkins UI
- Pipeline will automatically use AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
- Cleaner for development

---

#### Option D: AWS CLI Configuration File (LOCAL MACHINE)

Best for **permanent local setup**

**Step 1: Configure AWS CLI**

```bash
# Run this command
aws configure

# It will prompt:
# AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key [None]: 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
# Default region name [None]: ap-south-1
# Default output format [None]: json
```

**Step 2: Credentials Stored in ~/.aws/credentials**

```bash
# On Windows:
# C:\Users\{USERNAME}\.aws\credentials
# C:\Users\{USERNAME}\.aws\config

# On Linux/Mac:
# ~/.aws/credentials
# ~/.aws/config

# File content:
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = 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
region = ap-south-1
```

**Step 3: Verify Connection**

```bash
aws sts get-caller-identity

# Output:
# {
#   "UserId": "AIDAJ45Q7YFFARQ7PLBIFQ",
#   "Account": "123456789012",
#   "Arn": "arn:aws:iam::123456789012:user/your-username"
# }
```

**Step 4: Jenkins Will Use This Automatically**

- Jenkins runs as local user
- AWS CLI reads from ~/.aws/credentials automatically
- No credentials stored in Jenkins UI needed

---

#### Option E: Jenkins Credentials + Environment Variables (RECOMMENDED FOR LOCAL)

**Combine both for flexibility:**

**Step 1: Add AWS Credentials in Jenkins UI** (Option A above)

**Step 2: Also Set Environment Variables** (Option C above)

**Step 3: In Jenkinsfile, Use:**

```groovy
pipeline {
    agent any
    
    environment {
        AWS_REGION = "ap-south-1"
        // Jenkins will use aws-credentials automatically
    }
    
    stages {
        stage('Test AWS Access') {
            steps {
                withAWS(credentials: 'aws-credentials', region: 'ap-south-1') {
                    sh 'aws sts get-caller-identity'
                }
            }
        }
    }
}
```

---

### 3.3 Configure Git Repository (For Local Jenkins)

1. Go to **Manage Jenkins → System Configuration**
2. Scroll to **Git**
3. Set:
   - **Git executable**: Auto-detected (usually correct)
   - **Global Config user.name**: Your name
   - **Global Config user.email**: Your email

4. For **Private Git Repositories**:
   - Jenkins → Manage Credentials → Add Credentials
   - Kind: **SSH Key** or **Username with password**
   - Paste SSH key or GitHub token

### 3.4 Create Jenkins Pipeline Job (Complete Steps)

**Step 1: Click "New Item"**

```
Jenkins Home → New Item (top-left)
```

**Step 2: Enter Job Name**

```
Job name: webapp-terraform-pipeline
```

**Step 3: Select Pipeline**

```
Select: "Pipeline" (NOT "Freestyle Job")
Click: OK
```

**Step 4: Configure General Settings**

```
┌─────────────────────────────────────┐
│ Description:                        │
│ Deploy webapp to EKS via Terraform  │
│                                     │
│ [✓] This project is parameterized  │
│ [✓] Discard old builds              │
│     Max # of builds to keep: 30     │
│ [✓] GitHub project                 │
│     Project URL: <your-git-repo>    │
└─────────────────────────────────────┘
```

**Step 5: Build Parameters (if needed)**

```
These match Jenkinsfile.terraform parameters:

Add Parameter:
1. String Parameter
   - Name: AWS_REGION
   - Default: ap-south-1

2. String Parameter
   - Name: ENVIRONMENT
   - Default: dev

3. Boolean Parameter
   - Name: BUILD_AND_PUSH_IMAGE
   - Default: unchecked

etc...
```

**Step 6: Configure Pipeline Source (THIS IS KEY)**

```
Pipeline section:
┌──────────────────────────────────────────────┐
│ Definition: Pipeline script from SCM         │ ← Select this
│                                              │
│ SCM: Git                                     │
│                                              │
│ Repository URL:                              │
│ https://github.com/your-org/webapp...git    │
│                                              │
│ Credentials:                                 │
│ (none) or select SSH key if private repo    │
│                                              │
│ Branch:                                      │
│ */main  (or */develop)                       │
│                                              │
│ Script Path:                                 │
│ Jenkinsfile.terraform                       │ ← IMPORTANT!
│                                              │
└──────────────────────────────────────────────┘
```

**Step 7: Save Configuration**

```
Click: "Save"
```

**Step 8: Test Pipeline Job**

```
Jenkins Job Page:
Click: "Build with Parameters" (or just "Build")

Expected:
- Stage 1: Checkout - pulls code
- Stage 2: Validate AWS - shows credentials work
- Stage 3+: Terraform stages execute
```

---

### 3.5 Complete Local Jenkins Setup Example

**All steps in one place for LOCAL Jenkins:**

```bash
# 1. Get AWS Access Keys from AWS Console
# Copy: Access Key ID and Secret Access Key

# 2. Set environment variables (PowerShell)
$env:AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
$env:AWS_SECRET_ACCESS_KEY = "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"
$env:AWS_DEFAULT_REGION = "us-west-2"

# 3. Verify AWS CLI works
aws sts get-caller-identity

# 4. Test Terraform locally first
cd terraform
terraform init -reconfigure \
  -backend-config="bucket=harish-terraform-state-bucket" \
  -backend-config="region=ap-south-1" \
  -backend-config="key=terraform/terraform.tfstate"

# 5. If Terraform works, Jenkins will work

# 6. Open Jenkins Web UI
# Windows: http://localhost:8080
# Docker: http://localhost:8080 (if running in Docker)

# 7. Add AWS Credentials in Jenkins UI
# Manage Jenkins → Manage Credentials → Add AWS Credentials
# ID: aws-credentials
# Access Key: [from AWS]
# Secret: [from AWS]

# 8. Create Pipeline Job
# New Item → Pipeline → Configure → Save

# 9. Build the job
# Build with Parameters → Build Now
```

---



---

## Part 4: Pipeline Execution (Step-by-Step)

### 4.1 First Run - Terraform Initialization

1. Click **Build with Parameters**
2. Set parameters:
   ```
   AWS_REGION: ap-south-1
   TF_STATE_BUCKET: harish-terraform-state-bucket
   LOCK_TABLE: my-terraform-lock-table
   ENVIRONMENT: dev
   ECR_REGISTRY: [leave blank for now]
   BUILD_AND_PUSH_IMAGE: false
   SKIP_BACKEND_CREATION: false
   ```
3. Click **Build**

**Expected Output:**
```
[*] Checkout
[*] Build and Push Docker Image (SKIPPED - BUILD_AND_PUSH_IMAGE=false)
[*] Validate AWS Access
✓ "arn:aws:iam::123456789:user/jenkins-user"

[*] Prepare Backend
✓ Terraform state bucket already exists
✓ Terraform lock table already exists

[*] Terraform Init
✓ Successfully configured the backend 's3'
✓ Terraform has been successfully initialized

[*] Select Workspace
✓ Using Terraform workspace: dev

[*] Terraform Validate
✓ Success! The configuration is valid.

[*] Terraform Plan
Plan: 50 to add, 0 to change, 0 destroy.

[*] Terraform Apply
✓ Apply complete! Resources: 50 added.
```

### 4.2 Second Run - Build & Push Docker Image

1. Create ECR repository first:
   ```bash
   aws ecr create-repository --repository-name webapp --region ap-south-1
   ```

2. Get ECR registry URL:
   ```bash
   AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
   echo "${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com"
   ```

3. Click **Build with Parameters**
4. Set parameters:
   ```
   AWS_REGION: us-west-2
   TF_STATE_BUCKET: harish-terraform-state-bucket
   ENVIRONMENT: dev
   ECR_REGISTRY: 123456789.dkr.ecr.ap-south-1.amazonaws.com
   ECR_REPOSITORY: webapp
   BUILD_AND_PUSH_IMAGE: true
   CODEBUILD_PROJECT: [leave blank]
   SKIP_BACKEND_CREATION: true
   ```
5. Click **Build**

**Expected Output:**
```
[*] Checkout
[*] Build and Push Docker Image
  ✓ Login to ECR
  ✓ Building Docker image...
  ✓ Tagging image
  ✓ Pushing to ECR: 123456789.dkr.ecr.ap-south-1.amazonaws.com/webapp:42-a1b2c3d
  ✓ Pushing to ECR: ...webapp:latest

[*] Docker image pushed to ECR successfully
```

---

## Part 5: What Happens When Pipeline Runs

### Stage 1: Checkout
- Clones your Git repository
- Makes `ci/parse_branch_env` executable

### Stage 2: Build and Push Docker Image (if enabled)
- Logs into ECR using AWS credentials
- Builds Docker image from Dockerfile
- Tags with: `{BUILD_NUMBER}-{GIT_COMMIT_SHORT}`
- Pushes to ECR with both specific and `latest` tags

### Stage 3: Validate AWS Access
- Verifies Jenkins has AWS credentials
- Returns current IAM user/role

### Stage 4: Prepare Backend
- Creates S3 bucket (if doesn't exist)
- Creates DynamoDB table (if doesn't exist)

### Stage 5: Terraform Init
- Downloads AWS/Kubernetes/Helm providers
- Configures S3 backend for state storage
- Sets up workspace

### Stage 6: Select Workspace
- Maps Git branch to environment:
  - `main` → `prod` workspace
  - `develop` → `dev` workspace
  - `qa` → `qa` workspace
  - Others → sanitized branch name

### Stage 7: Terraform Validate
- Checks syntax
- Validates configuration

### Stage 8: Terraform Plan
- Generates infrastructure plan
- Shows what will be created

### Stage 9: Terraform Apply
- Creates all AWS resources (20-30 minutes for EKS)
- Deploys Helm charts (ALB controller, Prometheus, etc.)
- Deploys Kubernetes demo app

---

## Part 6: Verification After Pipeline Success

### 6.1 Check EKS Cluster
```bash
# Update kubeconfig
aws eks update-kubeconfig --name dev-webapp-cluster --region ap-south-1

# Verify access
kubectl get nodes
kubectl get pods --all-namespaces
```

### 6.2 Check Docker Image in ECR
```bash
# List images in ECR
aws ecr describe-images \
  --repository-name webapp \
  --region us-west-2

# Expected: Image with tags like "42-a1b2c3d" and "latest"
```

### 6.3 Check Application Deployment
```bash
# Check demo app
kubectl get deployment -n demo
kubectl get pods -n demo

# Get ALB endpoint (wait 2-3 minutes)
kubectl get ingress -n demo

# Test app
ALB=$(kubectl get ingress demo-nginx-ingress -n demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$ALB/
```

### 6.4 Access Monitoring
```bash
# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Login: admin / dev-grafana-admin

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# CloudWatch logs
aws logs tail /aws/eks/dev-webapp-cluster/cluster --follow
```

---

## Part 7: Common Issues & Solutions

### Issue 1: "Credentials not available"
```
Error: No credentials in Jenkins
```

**Solution:**
```bash
# Add AWS credentials to Jenkins
# Jenkins → Manage Credentials → Global → Add AWS Credentials
# Or set environment variables:
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

### Issue 2: "Failed to create S3 bucket in ap-south-1"
```
Error: The region... does not exist
```

**Solution:** Update backend.tf region to `ap-south-1`:
```hcl
# terraform/backend.tf
region = "us-west-2"
```

### Issue 3: "ECR login failed"
```
Error: no credentials provided
```

**Solution:**
```bash
# Ensure Jenkins has ECR permissions
aws ecr get-login-password --region us-west-2 | docker login \
  --username AWS --password-stdin {ECR_REGISTRY}
```

### Issue 4: "Docker not found"
```
Error: docker: command not found
```

**Solution:** Install Docker on Jenkins agent:
```bash
# Ubuntu/Debian
sudo apt-get install docker.io

# Or use CodeBuild option in Jenkins (no Docker needed on agent)
```

### Issue 5: "Terraform backend already configured"
```
Error: Backend initialization required, but not allowed by -backend=false
```

**Solution:**
```bash
# Option 1: Allow reconfiguration
terraform init -reconfigure

# Option 2: Remove .terraform directory (loses local cache)
rm -rf terraform/.terraform
terraform init
```

---

## Part 8: Setup Checklist

Before running pipeline, verify:

### AWS Setup
- [ ] S3 bucket `harish-terraform-state-bucket` exists in `ap-south-1`
- [ ] DynamoDB table `my-terraform-lock-table` exists (with LockID partition key)
- [ ] terraform/backend.tf has `region = "ap-south-1"`
- [ ] ECR repository `webapp` created
- [ ] IAM user/role has required permissions

### Jenkins Setup
- [ ] AWS credentials configured in Jenkins
- [ ] Git repository configured
- [ ] Jenkinsfile.terraform in repository root
- [ ] Docker installed on agent (if using local build)
- [ ] Pipeline job created pointing to Jenkinsfile.terraform

### Pipeline Parameters
- [ ] AWS_REGION: `ap-south-1` (matches bucket region)
- [ ] TF_STATE_BUCKET: `harish-terraform-state-bucket`
- [ ] LOCK_TABLE: `my-terraform-lock-table`
- [ ] ECR_REGISTRY: `{ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com`
- [ ] ECR_REPOSITORY: `webapp`

### First Run (Infrastructure Only)
- [ ] BUILD_AND_PUSH_IMAGE: `false` (Terraform first)
- [ ] SKIP_BACKEND_CREATION: `false`

### Second Run (Build & Push Image)
- [ ] BUILD_AND_PUSH_IMAGE: `true`
- [ ] SKIP_BACKEND_CREATION: `true` (backend already created)
- [ ] ECR_REGISTRY populated

---

## Quick Start Commands

### Setup AWS
```bash
# 1. Create S3 bucket
aws s3api create-bucket \
  --bucket harish-terraform-state-bucket \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# 2. Create DynamoDB table
aws dynamodb create-table \
  --table-name my-terraform-lock-table \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-2

# 3. Create ECR repository
aws ecr create-repository \
  --repository-name webapp \
  --region us-west-2

# 4. Get ECR registry URL
aws sts get-caller-identity --query Account --output text

# Output: {ACCOUNT_ID}
# ECR_REGISTRY: {ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com
```

### Test Jenkins
```bash
# Verify AWS access
aws sts get-caller-identity --region ap-south-1

# Verify S3 access
aws s3api head-bucket --bucket harish-terraform-state-bucket --region ap-south-1

# Verify ECR access
aws ecr get-login-password --region ap-south-1 | docker login \
  --username AWS --password-stdin {ECR_REGISTRY}
```

---

## Expected Timeline

| Phase | Duration | What Happens |
|-------|----------|-------------|
| AWS Setup | 5 min | Create S3, DynamoDB, ECR |
| Jenkins Config | 10 min | Add credentials, create job |
| First Pipeline Run | 30 min | Terraform downloads providers + creates EKS cluster |
| ALB Creation | 3 min | Load balancer provisioning (wait after terraform apply) |
| Second Pipeline Run | 5 min | Build and push Docker image to ECR |
| Total | ~1 hour | Ready for production |

---

## Next Actions

1. **Fix backend region**: Update `terraform/backend.tf` to `region = "ap-south-1"`
2. **Create AWS resources**: Run the quick start commands above
3. **Configure Jenkins**: Add AWS credentials and create pipeline job
4. **First run**: Execute with `BUILD_AND_PUSH_IMAGE=false`
5. **Verify**: Check EKS cluster, ALB endpoint, monitoring dashboards
6. **Second run**: Execute with `BUILD_AND_PUSH_IMAGE=true` to push Docker image

---

**Status**: Pipeline ready (after AWS setup)  
**Last Updated**: June 2026
