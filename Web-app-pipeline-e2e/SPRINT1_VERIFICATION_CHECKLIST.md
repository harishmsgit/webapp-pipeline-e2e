# Sprint 1 Setup Verification Checklist

Use this checklist to verify each step of the Sprint 1 setup. Check off items as you complete them.

---

## Phase 1: Prerequisites & Planning (5 min)

- [ ] **AWS Account**
  - [ ] AWS account created and accessible
  - [ ] AWS region selected: `_________________` (e.g., ap-south-1)
  - [ ] AWS Account ID noted: `_________________`

- [ ] **Local Development**
  - [ ] Docker installed: `docker --version` ✓
  - [ ] Git installed: `git --version` ✓
  - [ ] Node.js 18+ installed: `node --version` ✓
  - [ ] AWS CLI v2 installed: `aws --version` ✓

- [ ] **Repository Access**
  - [ ] Repository cloned locally
  - [ ] Git credentials configured
  - [ ] Can push to repository (test with git push)

---

## Phase 2: Local Application Testing (10 min)

- [ ] **Application Runs Locally**
  - [ ] `npm install` completed without errors
  - [ ] `node app/server.js` starts server on port 3000
  - [ ] `curl http://localhost:3000` returns success response
  - [ ] Server stopped cleanly

- [ ] **Docker Image Builds**
  - [ ] `docker build -t web-app-sprint1:latest .` completes
  - [ ] `docker images | grep web-app-sprint1` shows image
  - [ ] Image size noted: `_________________` MB

- [ ] **Docker Container Runs**
  - [ ] `docker run -p 3000:3000 web-app-sprint1:latest` starts container
  - [ ] `curl http://localhost:3000` works from container
  - [ ] Container stops cleanly

- [ ] **Docker Compose Works**
  - [ ] `docker compose config` validates successfully
  - [ ] `docker compose up --build` starts services
  - [ ] Services accessible at configured ports
  - [ ] `docker compose down` stops services cleanly

---

## Phase 3: AWS Setup (15 min)

- [ ] **IAM Role Created**
  - [ ] Role name: `jenkins-sprint1-ec2-role`
  - [ ] IAM role exists in AWS console
  - [ ] Permissions policy attached:
    - [ ] ECR permissions
    - [ ] STS GetCallerIdentity
    - [ ] EKS describe permissions

- [ ] **Instance Profile Created**
  - [ ] Profile name: `jenkins-sprint1-instance-profile`
  - [ ] Role added to instance profile
  - [ ] Can be attached to EC2 instances

- [ ] **Security Group Created**
  - [ ] Security group name: `jenkins-sprint1-sg`
  - [ ] Inbound rule: SSH (22) from your IP or 0.0.0.0/0
  - [ ] Inbound rule: HTTP (8080) from your IP or 0.0.0.0/0
  - [ ] Inbound rule: Agent (50000) from your IP or 0.0.0.0/0

- [ ] **ECR Repository Created**
  - [ ] Repository name: `web-app-sprint1`
  - [ ] Repository URI: `_________________`
    (Format: `ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/web-app-sprint1`)
  - [ ] Tag mutability: Enabled
  - [ ] Image scanning: Enabled

---

## Phase 4: EC2 Instance Launch (10 min)

- [ ] **EC2 Instance Launched**
  - [ ] Instance name: `jenkins-sprint1`
  - [ ] AMI: Ubuntu 24.04 LTS or Amazon Linux 2023
  - [ ] Instance type: `t3.medium` or `t3.large`
  - [ ] Key pair: `_________________` (saved locally)
  - [ ] IAM instance profile: `jenkins-sprint1-instance-profile`
  - [ ] Security group: `jenkins-sprint1-sg`
  - [ ] Storage: 30GB+ gp3

- [ ] **Instance Running**
  - [ ] Instance state: Running
  - [ ] Status checks: 2/2 passed
  - [ ] Public IP address: `_________________`
  - [ ] Can SSH: `ssh -i key.pem ubuntu@<IP>` ✓

---

## Phase 5: Jenkins & Dependencies Installation (20 min)

- [ ] **System Updates**
  - [ ] `sudo apt update` ✓
  - [ ] `sudo apt upgrade -y` ✓

- [ ] **Docker Installed**
  - [ ] Docker version: `_________________`
  - [ ] `docker --version` ✓
  - [ ] Docker daemon running: `sudo systemctl status docker` ✓
  - [ ] Jenkins user in docker group: `groups jenkins` includes docker

- [ ] **AWS CLI Installed**
  - [ ] AWS CLI version: `_________________`
  - [ ] `aws --version` ✓
  - [ ] `aws sts get-caller-identity` returns account info ✓

- [ ] **Java Installed**
  - [ ] Java version: `_________________`
  - [ ] `java -version` ✓

- [ ] **Git Installed**
  - [ ] Git version: `_________________`
  - [ ] `git --version` ✓

- [ ] **Jenkins Installed**
  - [ ] Jenkins version: `_________________`
  - [ ] Jenkins service enabled: `sudo systemctl is-enabled jenkins` ✓
  - [ ] Jenkins service running: `sudo systemctl status jenkins` ✓

---

## Phase 6: Jenkins Initialization (15 min)

- [ ] **Jenkins UI Accessible**
  - [ ] Jenkins URL: `http://_________________:8080`
  - [ ] Jenkins unlock page loads
  - [ ] Initial admin password obtained from:
    `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`

- [ ] **Jenkins Unlocked**
  - [ ] Unlock page dismissed
  - [ ] Plugin installation started

- [ ] **Plugins Installed**
  - [ ] Suggested plugins installed (5-10 min)
  - [ ] Confirmed plugins:
    - [ ] Pipeline
    - [ ] Git
    - [ ] Docker Pipeline
    - [ ] Credentials Binding
    - [ ] AWS Steps (optional)
    - [ ] Amazon ECR (optional)
    - [ ] Blue Ocean (optional)

- [ ] **First Admin User Created**
  - [ ] Username: `_________________`
  - [ ] Email: `_________________`
  - [ ] User saved and Jenkins home page accessible

- [ ] **Jenkins URL Configured**
  - [ ] Jenkins URL: `http://<PUBLIC_IP>:8080/`
  - [ ] Configuration saved

---

## Phase 7: Jenkins Configuration (10 min)

- [ ] **System Configuration**
  - [ ] Number of executors: 4 or more
  - [ ] Master/agent timeout: default or configured
  - [ ] Configuration saved

- [ ] **Required Plugins Verified**
  - [ ] Navigate to Manage Jenkins → Manage Plugins
  - [ ] Verify all plugins from Phase 6 are installed

- [ ] **AWS Credentials (if using manual credentials)**
  - [ ] If using IAM role, skip this section
  - [ ] If using stored credentials:
    - [ ] Navigate to Manage Jenkins → Credentials
    - [ ] Click (global) domain
    - [ ] AWS credentials created with ID: `aws-sprint1`
    - [ ] Access key and secret verified (don't display)

---

## Phase 8: Git Integration Setup (5 min)

- [ ] **Public Repository**
  - [ ] If repository is public, skip Git credentials setup

- [ ] **Private Repository - Git Credentials**
  - [ ] Git credentials created in Jenkins
    - [ ] Type: Username with password OR SSH key
    - [ ] Username/ID: `_________________`
    - [ ] Credentials: Secure token or SSH key
    - [ ] ID: `git-sprint1-creds`

- [ ] **Git Webhook Configured (GitHub)**
  - [ ] Navigate to repository Settings → Webhooks
  - [ ] Webhook URL: `http://<JENKINS_IP>:8080/github-webhook/`
  - [ ] Content type: application/json
  - [ ] Events: Just the push event
  - [ ] Webhook created and green checkmark showing

---

## Phase 9: Jenkins Pipeline Job Creation (10 min)

- [ ] **Pipeline Job Created**
  - [ ] Job name: `web-app-sprint1-pipeline`
  - [ ] Job type: Pipeline
  - [ ] Job configuration page opens

- [ ] **Repository Source Configured**
  - [ ] Pipeline Definition: `Pipeline script from SCM`
  - [ ] SCM: `Git`
  - [ ] Repository URL: `_________________`
  - [ ] Credentials: Selected (if private) or left empty (if public)
  - [ ] Branch specifier: `*/main` or `*/master`

- [ ] **Jenkinsfile Path Set**
  - [ ] Script Path: `Web-app-pipeline-e2e/Jenkinsfile`

- [ ] **Jenkinsfile Updated with AWS Details**
  - [ ] AWS_REGION in Jenkinsfile: `_________________`
  - [ ] AWS_ACCOUNT_ID in Jenkinsfile: `234951664603`
  - [ ] ECR_REPO_NAME in Jenkinsfile: `web-app-sprint1`

- [ ] **Build Triggers Configured (Optional)**
  - [ ] GitHub hook trigger enabled (for GitHub webhook)
  - [ ] OR Poll SCM configured (e.g., `H/5 * * * *`)

- [ ] **Job Configuration Saved**
  - [ ] Configuration saved successfully
  - [ ] Pipeline job visible in Jenkins home

---

## Phase 10: Manual Build Test (15 min)

- [ ] **First Build Triggered**
  - [ ] Click "Build Now" on pipeline job
  - [ ] Build #1 appears in Build History

- [ ] **Build Console Output Monitored**
  - [ ] Click build #1 → Console Output
  - [ ] Follow build progress through stages:

- [ ] **Build Stages Complete**
  - [ ] ✅ Checkout: Repository checked out
  - [ ] ✅ Validate AWS Access: Credentials valid, account ID shown
  - [ ] ✅ Build Docker Image: Image built successfully
  - [ ] ✅ Login to ECR: ECR authentication successful
  - [ ] ✅ Ensure ECR Repository: Repository exists or created
  - [ ] ✅ Push Image to ECR: Image pushed with tag
  - [ ] ✅ Verify ECR Image: Image listed in ECR

- [ ] **Build Successful**
  - [ ] Build status: SUCCESS (blue circle)
  - [ ] Build duration: `_________________` seconds
  - [ ] Image tag pushed: `_________________` (e.g., build ID)

- [ ] **Image Verified in ECR**
  - [ ] Navigate to AWS ECR console → web-app-sprint1
  - [ ] Latest build image visible in repository
  - [ ] Image tag matches Jenkins build ID
  - [ ] Image size: `_________________` MB

---

## Phase 11: Git Webhook Integration Test (5 min)

- [ ] **Code Change Made**
  - [ ] Local file modified (e.g., update README.md)
  - [ ] Change committed: `git add -A && git commit -m "Test webhook"`
  - [ ] Change pushed: `git push origin main`

- [ ] **Build Triggered Automatically**
  - [ ] Within 30 seconds, build #2 appears in Jenkins
  - [ ] Build was NOT triggered manually
  - [ ] Build status: SUCCESS

- [ ] **New Image in ECR**
  - [ ] New image tag appears in ECR
  - [ ] Tag matches new build ID

---

## Phase 12: Container Runtime Test (10 min)

- [ ] **Image Pulled from ECR**
  - [ ] SSH to Jenkins EC2 instance
  - [ ] Pull command executed:
    ```bash
    aws ecr get-login-password --region ap-south-1 | \
docker login --username AWS --password-stdin \
234951664603.dkr.ecr.ap-south-1.amazonaws.com

    
    docker pull 234951664603.dkr.ecr.ap-south-1.amazonaws.com/web-app-sprint1:latest
    ```
  - [ ] Pull completed successfully

- [ ] **Container Runs from ECR Image**
  - [ ] Container started:
    ```bash
    docker run -p 3000:3000 234951664603.dkr.ecr.ap-south-1.amazonaws.com/web-app-sprint1:latest
    ```
  - [ ] Container started without errors
  - [ ] Server listening on port 3000

- [ ] **Application Responds**
  - [ ] From another terminal (or local machine):
    ```bash
    curl http://13.207.84.100:3000
    ```
  - [ ] Response received: `Sprint 1 Web Application - CI/CD Pipeline Ready`

- [ ] **Container Stopped**
  - [ ] Container stopped cleanly: `Ctrl+C` or `docker stop <ID>`

---

## Phase 13: Documentation & Knowledge Base (5 min)

- [ ] **Documentation Reviewed**
  - [ ] [SPRINT1_SETUP_GUIDE.md](SPRINT1_SETUP_GUIDE.md) reviewed
  - [ ] [doc/architecture-sprint1.md](doc/architecture-sprint1.md) read
  - [ ] [doc/jenkins-setup.md](doc/jenkins-setup.md) reviewed

- [ ] **Key Information Documented**
  - [ ] AWS Region: `_________________`
  - [ ] AWS Account ID: `_________________`
  - [ ] EC2 Public IP: `_________________`
  - [ ] Jenkins URL: `_________________`
  - [ ] ECR Repository URI: `_________________`
  - [ ] Git Repository URL: `_________________`
  - [ ] Database credentials (if any): `_________________` (store securely)

- [ ] **Troubleshooting Reference Saved**
  - [ ] [SPRINT1_SETUP_GUIDE.md#troubleshooting](SPRINT1_SETUP_GUIDE.md#troubleshooting) bookmarked
  - [ ] Common error solutions noted

---

## Sprint 1 Completion Summary

**Total Setup Time**: 90-120 minutes

### ✅ Verified Components

- [ ] Application architecture designed
- [ ] Application Dockerized and tested locally
- [ ] AWS resources created (IAM, ECR, Security Group)
- [ ] EC2 instance running with Jenkins
- [ ] Jenkins properly configured with all required plugins
- [ ] Git integration working (webhook or polling)
- [ ] Jenkins pipeline job created from Jenkinsfile
- [ ] End-to-end pipeline tested (from code push to ECR image)
- [ ] Docker image validated running from ECR

### 📊 Sprint 1 Metrics

- **Build success rate**: `____%` (Target: 100%)
- **Build time**: `____` minutes (Target: < 5 min)
- **Image size**: `____` MB
- **Manual test duration**: `____` minutes
- **Automated test duration**: `____` minutes

### 🎯 Sprint 1 Status

**Status**: ✅ **COMPLETE**

All Sprint 1 deliverables are complete:
- ✅ Application architecture designed
- ✅ Application Dockerized
- ✅ Jenkins server set up on AWS EC2
- ✅ AWS resources configured
- ✅ Git integration active
- ✅ CI/CD pipeline operational

### 📝 Notes and Issues Encountered

```
Notes:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

Issues Resolved:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

Recommendations for Sprint 2:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

### 🔄 Next Steps: Sprint 2

- [ ] Provision AWS VPC and subnets with Terraform
- [ ] Create AWS EKS cluster
- [ ] Configure Kubernetes namespaces and RBAC
- [ ] Set up ArgoCD for GitOps deployment
- [ ] Create Terraform pipeline in Jenkins

---

**Setup Date**: `_________________`  
**Completed By**: `_________________`  
**Review Date**: `_________________`  
**Reviewed By**: `_________________`
