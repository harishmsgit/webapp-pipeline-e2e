# Local Jenkins Setup Guide (Not on EC2)

**For**: Developers who want to run Jenkins locally and connect to AWS using Access Key + Secret Key

**Requirement**: Docker, AWS account with IAM user, Git installed

---

## ⚡ Quick 10-Minute Setup

### 1. Get AWS Credentials (2 minutes)

```bash
# Open AWS Console:
# IAM → Users → Your User → Security credentials → Create Access Key

# You will get:
# Access Key ID:     AKIAIOSFODNN7EXAMPLE
# Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPOkYRELKZZLZrLH81

# KEEP THESE SAFE - Don't share or commit to Git!
```

---

### 2. Start Jenkins Locally (2 minutes)

#### Option A: Docker (Recommended)

```bash
# Pull Jenkins image
docker pull jenkins/jenkins:lts

# Run Jenkins container
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts

# Wait 30 seconds, then visit: http://localhost:8080

# Get initial admin password
docker logs jenkins | grep "initialAdminPassword"
# Copy the password from logs
```

#### Option B: Windows Local Installation

```powershell
# Download from: https://www.jenkins.io/download/

# Install MSI package
# During install:
# - Check "Run service as LocalSystem"
# - Default port: 8080

# After install:
# - Open: http://localhost:8080
# - Unlock Jenkins with initial password

# Get password:
# C:\Program Files\Jenkins\secrets\initialAdminPassword
```

#### Option C: Linux Local Installation

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install jenkins

# Start service
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Visit: http://localhost:8080
```

---

### 3. Setup Jenkins (2 minutes)

```
1. Unlock Jenkins
   - Paste password from step above
   - Click "Continue"

2. Install Suggested Plugins
   - Click "Install suggested plugins"
   - Wait ~5 minutes

3. Create Admin User
   - Username: admin (or your name)
   - Password: (strong password)
   - Full Name: Jenkins Admin
   - Email: your-email@example.com
   - Click "Save and Continue"

4. Instance Configuration
   - Jenkins URL: http://localhost:8080/
   - Click "Save and Finish"
```

---

### 4. Add AWS Credentials to Jenkins (2 minutes)

```
1. Jenkins Home Page
2. Click: "Manage Jenkins" (left sidebar)
3. Click: "Manage Credentials"
4. Click: "Global credentials (unrestricted)" (under "Stores" section)
5. Click: "Add Credentials" (left sidebar)

6. Fill the form:
   ┌──────────────────────────────────────────┐
   │ Kind:                AWS Credentials      │
   │ Scope:               Global (unrestricted)│
   │ Access Key ID:       AKIA...              │ ← Paste your AWS Access Key
   │ Secret Access Key:   [paste secret]       │ ← Paste your AWS Secret Key
   │ ID:                  aws-credentials      │ ← This is the reference name
   │ Description:         Jenkins AWS Access   │
   └──────────────────────────────────────────┘

7. Click: "Create"
8. Success message: "Credentials added"
```

**Visual Step-by-Step**:
```
Jenkins Dashboard
  ↓
Manage Jenkins (sidebar)
  ↓
Manage Credentials
  ↓
Global credentials (unrestricted)
  ↓
Add Credentials (sidebar)
  ↓
Select "AWS Credentials" from Kind dropdown
  ↓
Fill Access Key ID
  ↓
Fill Secret Access Key
  ↓
Set ID: aws-credentials
  ↓
Click Create
  ↓
✓ Credentials saved
```

---

### 5. Create Pipeline Job (2 minutes)

```
1. Jenkins Home Page
2. Click: "New Item" (left sidebar)

3. Enter Job Name:
   webapp-terraform-pipeline

4. Select: "Pipeline" (radio button)

5. Click: "OK"

6. Scroll down to "Pipeline" section:
   
   Definition: [Pipeline script from SCM]  ← SELECT THIS
   
   SCM: [Git]
   
   Repository URL:
   https://github.com/your-user/webapp-pipeline-e2e.git
   
   Credentials:
   (leave blank if public, or add SSH key if private)
   
   Branch:
   */develop  (or */main)
   
   Script Path:
   Jenkinsfile.terraform

7. Click: "Save"

8. Click: "Build with Parameters" (or just "Build")
```

---

## Detailed Steps for Local Jenkins with AWS Credentials

### Step 1: Create IAM User with AWS Access Keys

**In AWS Console:**

1. Go to: **IAM → Users**
2. Click: **Create user**
3. Username: `jenkins-ci-user`
4. Click: **Next**
5. Click: **Attach policies directly**
6. Search for and select:
   - `AmazonS3FullAccess` (Terraform state)
   - `AmazonDynamoDBFullAccess` (State locking)
   - `AmazonEKSFullAccess` (EKS cluster)
   - `AmazonEC2FullAccess` (Networking)
   - `AmazonIAMFullAccess` (Roles/policies)
   - `AmazonEC2ContainerRegistryFullAccess` (ECR)
7. Click: **Next**
8. Click: **Create user**
9. Click on user name: `jenkins-ci-user`
10. Go to: **Security credentials**
11. Click: **Create access key**
12. Select: **Local code**
13. Click: **Next**
14. Click: **Create access key**
15. Copy and save:
    - **Access Key ID**
    - **Secret Access Key**

---

### Step 2: Install Jenkins Locally

```bash
# Option 1: Docker (Simplest)
docker pull jenkins/jenkins:lts
docker run -d --name jenkins -p 8080:8080 -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts

# Option 2: Direct Installation
# Download from: https://www.jenkins.io/download/
# Follow installation wizard

# Verify Jenkins is running
curl http://localhost:8080

# Expected output: Jenkins HTML page
```

---

### Step 3: Initial Jenkins Setup

```
1. Open: http://localhost:8080
2. Unlock with initial password:
   - Docker: docker logs jenkins | grep initialAdminPassword
   - Local: C:\Program Files\Jenkins\secrets\initialAdminPassword
3. Install suggested plugins (takes 5-10 min)
4. Create admin user
5. Instance configuration (use default)
```

---

### Step 4: Configure AWS Credentials

```
1. Jenkins Home
2. Manage Jenkins → Manage Credentials
3. Global credentials (unrestricted)
4. Add Credentials

Form to fill:
┌─────────────────────────────────────────────┐
│ Kind: AWS Credentials                       │
│ Scope: Global (unrestricted)                │
│ Access Key ID: AKIAIOSFODNN7EXAMPLE         │
│ Secret Access Key: wJalrXUtnFEMI/K7...      │
│ ID: aws-credentials                         │
│ Description: Jenkins AWS Credentials        │
└─────────────────────────────────────────────┘

5. Click Create
6. You should see: "aws-credentials (AWS Credentials)"
```

---

### Step 5: Add GitHub Repository (if using Git SSH)

```
1. Manage Jenkins → Manage Credentials
2. Global credentials (unrestricted)
3. Add Credentials

For GitHub Private Repo:
┌─────────────────────────────────────────────┐
│ Kind: SSH Key                               │
│ Scope: Global (unrestricted)                │
│ Username: git                               │
│ Private Key: [paste your SSH private key]   │
│ Passphrase: [if key has one]                │
│ ID: github-ssh                              │
│ Description: GitHub SSH Key                 │
└─────────────────────────────────────────────┘

For GitHub Personal Token:
┌─────────────────────────────────────────────┐
│ Kind: Username with password                │
│ Scope: Global (unrestricted)                │
│ Username: your-github-username              │
│ Password: your-github-token                 │
│ ID: github-token                            │
│ Description: GitHub PAT                     │
└─────────────────────────────────────────────┘
```

---

### Step 6: Create Pipeline Job

```
1. Click: New Item
2. Name: webapp-terraform-pipeline
3. Type: Pipeline
4. Click: OK

5. Configuration:
   ┌──────────────────────────────────────────┐
   │ Description:                             │
   │ Deploy webapp to EKS via Terraform       │
   │                                          │
   │ Pipeline:                                │
   │ Definition: Pipeline script from SCM     │
   │ SCM: Git                                 │
   │ Repository URL: https://github.com/...   │
   │ Credentials: github-ssh (or github-token)│
   │ Branch: */develop                        │
   │ Script Path: Jenkinsfile.terraform       │
   └──────────────────────────────────────────┘

6. Click: Save
```

---

### Step 7: Test Pipeline

```
1. Click: Build with Parameters

2. Parameters:
   AWS_REGION = ap-south-1
   TF_STATE_BUCKET = harish-terraform-state-bucket
   LOCK_TABLE = my-terraform-lock-table
   ENVIRONMENT = dev
   ECR_REGISTRY = (leave blank for first run)
   BUILD_AND_PUSH_IMAGE = false
   SKIP_BACKEND_CREATION = false

3. Click: Build

4. Monitor progress:
   - Console Output shows each stage
   - Should see: ✓ AWS credentials validated
   - Should see: ✓ Terraform init successful
```

---

## Troubleshooting Local Jenkins

### Issue: "Credentials not available"

**Error**: 
```
Error: No AWS credentials provided
```

**Solution**:
```
1. Check if credentials are added:
   Manage Jenkins → Manage Credentials
2. Verify credential ID is: aws-credentials
3. Restart Jenkins:
   Docker: docker restart jenkins
   Windows: Services → Jenkins → Restart
```

---

### Issue: "Cannot access GitHub repository"

**Error**:
```
Error: git@github.com: Permission denied
```

**Solution**:
```
1. Generate GitHub SSH key:
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_jenkins

2. Add public key to GitHub:
   https://github.com/settings/keys → New SSH key
   Paste content of: ~/.ssh/github_jenkins.pub

3. Add private key to Jenkins:
   Manage Credentials → Add Credentials → SSH Key
   Paste content of: ~/.ssh/github_jenkins
```

---

### Issue: "Docker: command not found"

**Error**:
```
Error: docker: command not found
```

**Solution**:
```
Install Docker:

Windows:
- Download: https://www.docker.com/products/docker-desktop
- Install and restart

Linux:
sudo apt-get install docker.io
sudo systemctl start docker

Mac:
brew install docker
docker run hello-world
```

---

### Issue: "Port 8080 already in use"

**Error**:
```
Error: Address already in use :8080
```

**Solution**:
```bash
# Find process using port 8080
netstat -ano | findstr :8080  (Windows)
lsof -i :8080                 (Linux/Mac)

# Kill process or use different port
docker run -d --name jenkins -p 8090:8080 jenkins/jenkins:lts
# Now access: http://localhost:8090
```

---

## Environment Variables Alternative

If you don't want to store credentials in Jenkins UI:

```bash
# Windows PowerShell
$env:AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
$env:AWS_SECRET_ACCESS_KEY = "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"
$env:AWS_DEFAULT_REGION = "ap-south-1"

# Restart Jenkins
docker restart jenkins

# Jenkins will automatically use these variables
```

---

## Complete Verification Checklist

Before running pipeline, verify all steps:

```
Local Jenkins Setup:
✓ Jenkins running on http://localhost:8080
✓ Can login with admin credentials
✓ AWS Credentials added (ID: aws-credentials)
✓ GitHub credentials added (if private repo)
✓ Pipeline job created: webapp-terraform-pipeline
✓ Can access job page

AWS Prerequisites:
✓ S3 bucket exists: harish-terraform-state-bucket (ap-south-1)
✓ DynamoDB table exists: my-terraform-lock-table
✓ ECR repository exists: webapp
✓ IAM user has permissions: S3, DynamoDB, EKS, EC2, IAM, ECR

Git Repository:
✓ Jenkinsfile.terraform exists in repo
✓ Can access from Jenkins (SSH key or token configured)
✓ Branch: */develop or */main accessible

Terraform Configuration:
✓ terraform/backend.tf has correct region
✓ terraform/variables.tf is correct
✓ All Terraform files valid (can run terraform validate locally)
```

---

## Quick Commands Reference

```bash
# Docker Jenkins
docker logs jenkins                      # See logs
docker exec -u root jenkins apt-get update       # Update packages
docker stop jenkins                      # Stop Jenkins
docker start jenkins                     # Start Jenkins
docker rm jenkins                        # Remove container

# AWS CLI
aws sts get-caller-identity              # Verify credentials
aws s3api head-bucket --bucket harish-terraform-state-bucket    # Test S3 access
aws ecr describe-repositories             # List ECR repos

# Terraform
terraform init
terraform init -reconfigure

wsl -e sh -lc 'cd /mnt/d/Capstone-projects/Sprint2/webapp-pipeline-e2e/Web-app-pipeline-e2e/terraform && terraform plan'

terraform validate                       # Check syntax
terraform plan -out=tfplan              # Generate plan
terraform apply tfplan                  # Apply changes
```

---

## Next Steps

1. **Create IAM user** with AWS access keys (5 min)
2. **Start Jenkins locally** with Docker or local install (5 min)
3. **Add AWS credentials** in Jenkins UI (2 min)
4. **Create pipeline job** pointing to Jenkinsfile.terraform (2 min)
5. **Run first build** with BUILD_AND_PUSH_IMAGE=false (30 min)
6. **Verify EKS cluster** created successfully
7. **Run second build** with BUILD_AND_PUSH_IMAGE=true (5 min)
8. **Access application** via ALB endpoint

**Total Setup Time**: ~1 hour (mostly EKS cluster creation in step 5)

---

**Status**: ✅ Ready for local development  
**Last Updated**: June 2026  
**Jenkins Version**: LTS (2.400+)  
**Terraform Version**: >= 1.5.0
