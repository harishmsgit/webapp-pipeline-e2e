# Sprint 1 Complete Setup Guide: Architecture, Dockerization, and Jenkins

This guide provides accurate, step-by-step instructions for completing Sprint 1 requirements: designing the application architecture, Dockerizing the web application, and setting up a Jenkins CI/CD pipeline on AWS EC2.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Validate Local Application](#step-1-validate-local-application)
4. [Step 2: AWS Account and IAM Setup](#step-2-aws-account-and-iam-setup)
5. [Step 3: Create ECR Repository](#step-3-create-ecr-repository)
6. [Step 4: Launch EC2 Instance for Jenkins](#step-4-launch-ec2-instance-for-jenkins)
7. [Step 5: Install Jenkins and Dependencies](#step-5-install-jenkins-and-dependencies)
8. [Step 6: Configure Jenkins](#step-6-configure-jenkins)
9. [Step 7: Set Up Git Integration](#step-7-set-up-git-integration)
10. [Step 8: Create and Test Jenkins Pipeline Job](#step-8-create-and-test-jenkins-pipeline-job)
11. [Step 9: Validate End-to-End Pipeline](#step-9-validate-end-to-end-pipeline)
12. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Sprint 1 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Git Repository                           │
│              (Your Source Code Branch)                      │
└─────────────────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                  Jenkins on EC2 (CI/CD)                     │
│  ┌────────────────────────────────────────────────────┐    │
│  │ Pipeline Stages:                                  │    │
│  │ 1. Checkout → Pull code from Git                  │    │
│  │ 2. Validate → Verify AWS access                   │    │
│  │ 3. Build → Docker build image                     │    │
│  │ 4. Login → Authenticate to AWS ECR                │    │
│  │ 5. Push → Push image to ECR repository            │    │
│  └────────────────────────────────────────────────────┘    │
│  • Node.js 20+ runtime                                     │
│  • Docker engine                                           │
│  • AWS CLI v2                                              │
│  • Git client                                              │
│  • IAM role for AWS access                                 │
└─────────────────────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│           AWS Elastic Container Registry (ECR)              │
│          Docker Image Storage (web-app-sprint1)             │
└─────────────────────────────────────────────────────────────┘
```

### Deployment Flow

1. Developer commits code to Git repository
2. Jenkins detects the change (via webhook or polling)
3. Jenkins checks out the repository
4. Jenkins builds a Docker image using the Dockerfile
5. Jenkins authenticates to AWS ECR using IAM role
6. Jenkins pushes the Docker image to ECR with version tag
7. Image is now ready for future sprints to deploy to EKS

---

## Prerequisites

Before starting, verify you have:

- [ ] AWS account with appropriate permissions
- [ ] Local development environment with:
  - Docker installed
  - Git installed
  - AWS CLI v2 installed
  - Node.js 18+ installed
- [ ] Access to this repository (Git credentials ready)
- [ ] AWS region selected (example: `ap-south-1`)
- [ ] AWS account ID (retrieve from AWS console)

### Local Validation Commands

```bash
# Verify Docker
docker --version
docker run hello-world

# Verify Git
git --version

# Verify Node.js
node --version
npm --version

# Verify AWS CLI (if already installed)
aws --version
aws sts get-caller-identity
```

---

## Step 1: Validate Local Application

### 1.1 Test Application Locally

Clone or navigate to the repository and validate the web application:

```bash
cd Web-app-pipeline-e2e
npm install
node app/server.js
```

Expected output:
```
Server running on port 3000
```

Visit `http://localhost:3000` and verify the response:
```
Sprint 1 Web Application - CI/CD Pipeline Ready
```

### 1.2 Test Docker Build Locally

Build the Docker image locally:

```bash
cd Web-app-pipeline-e2e
docker build -t web-app-sprint1:latest .
```

Expected output:
```
Successfully built <IMAGE_ID>
Successfully tagged web-app-sprint1:latest
```

### 1.3 Test Docker Image

Run the container locally:

```bash
docker run -p 3000:3000 web-app-pipeline-e2e-web:latest
```

Visit `http://localhost:3000` to verify the application responds.

### 1.4 Test Docker Compose

Validate the Docker Compose configuration:

```bash
docker compose config
docker compose up --build
```

Visit `http://localhost:5000` (note: docker-compose.yml uses port 5000).

Stop the container:
```bash
docker compose down
```

---

## Step 2: AWS Account and IAM Setup

### 2.1 Create IAM Role for EC2 Instance

This role grants Jenkins access to ECR and EKS resources.

**Via AWS Console:**

1. Navigate to **IAM** → **Roles** → **Create Role**
2. Select **AWS Service** → **EC2** → **Next**
3. Create an inline policy with the following JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAccess",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository"
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
    },
    {
      "Sid": "EKSDescribe",
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    }
  ]
}
```

4. Name the role: `jenkins-sprint1-ec2-role`
5. Complete role creation

**Via AWS CLI:**

Save the policy above to a file named `jenkins-policy.json`, then:

```bash
# Create trust policy
cat > jenkins-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create role
aws iam create-role \
  --role-name jenkins-sprint1-ec2-role \
  --assume-role-policy-document file://jenkins-trust-policy.json \
  --region ap-south-1

# Attach inline policy
aws iam put-role-policy \
  --role-name jenkins-sprint1-ec2-role \
  --policy-name jenkins-sprint1-ecr-policy \
  --policy-document file://jenkins-policy.json \
  --region ap-south-1

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name jenkins-sprint1-instance-profile \
  --region ap-south-1

# Add role to instance profile
aws iam add-role-to-instance-profile \
  --instance-profile-name jenkins-sprint1-instance-profile \
  --role-name jenkins-sprint1-ec2-role \
  --region ap-south-1
```

### 2.2 Retrieve Your AWS Account ID

```bash
aws sts get-caller-identity --query Account --output text
```

Save the Account ID. It will be used in later steps (e.g., `234951664603`).

### 2.3 Create Security Group

**Via AWS Console:**

1. Navigate to **EC2** → **Security Groups** → **Create Security Group**
2. Name: `jenkins-sprint1-sg`
3. Add inbound rules:
   - **SSH (22)**: Source = Your IP or 0.0.0.0/0 (for testing; restrict in production)
   - **Jenkins UI (8080)**: Source = Your IP or 0.0.0.0/0
   - **Jenkins Agents (50000)**: Source = Your VPC CIDR (or 0.0.0.0/0 for testing)
4. Create security group

**Via AWS CLI:**

```bash
# Create security group
SG_ID=$(aws ec2 create-security-group \
  --group-name jenkins-sprint1-sg \
  --description "Jenkins Sprint 1 Security Group" \
  --region ap-south-1 \
  --query 'GroupId' \
  --output text)

# Authorize SSH
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --region ap-south-1

# Authorize Jenkins UI (8080)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0 \
  --region ap-south-1

# Authorize Jenkins Agents (50000)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 50000 \
  --cidr 0.0.0.0/0 \
  --region ap-south-1

echo "Security Group ID: $SG_ID"
```

---

## Step 3: Create ECR Repository

### 3.1 Create ECR Repository

**Via AWS Console:**

1. Navigate to **Elastic Container Registry (ECR)** → **Create Repository**
2. Repository name: `web-app-sprint1`
3. Image tag mutability: Enable (recommended)
4. Scan on push: Enable (recommended)
5. Create repository

**Via AWS CLI:**

```bash
aws ecr create-repository \
  --repository-name web-app-sprint1 \
  --image-tag-mutability MUTABLE \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256 \
  --region ap-south-1
```

Expected output includes the repository URI:
```
"repositoryUri": "234951664603.dkr.ecr.ap-south-1.amazonaws.com/web-app-sprint1"
```

**Save this URI; it will be used in the Jenkinsfile.**

### 3.2 Verify Repository Creation

```bash
aws ecr describe-repositories \
  --repository-names web-app-sprint1 \
  --region ap-south-1
```

---

## Step 4: Launch EC2 Instance for Jenkins

### 4.1 Launch EC2 Instance

**Via AWS Console:**

1. Navigate to **EC2** → **Instances** → **Launch Instances**
2. **Name**: `jenkins-sprint1`
3. **AMI**: Choose one of:
   - Ubuntu 24.04 LTS
   - Ubuntu 22.04 LTS
   - Amazon Linux 2023
4. **Instance Type**: `t3.medium` (for testing) or `t3.large` (for production)
5. **Key Pair**: Create or select an existing key pair
6. **Network Settings**:
   - VPC: Default (or your chosen VPC)
   - Security Group: Select `jenkins-sprint1-sg` (created in Step 2.3)
7. **Storage**: 30GB+ gp3 (or gp2)
8. **IAM Instance Profile**: Select `jenkins-sprint1-instance-profile` (created in Step 2.1)
9. **User Data** (Advanced):
   - Copy the bootstrap script from Step 5 (bootstrap section) if needed
10. **Launch Instance**

**Via AWS CLI:**

```bash
# Get the latest Ubuntu 24.04 AMI ID (adjust region)
AMI_ID=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*" \
  "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text \
  --region ap-south-1)

# Get security group ID (replace with your SG ID)
SG_ID="sg-xxxxx"

# Launch instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.medium \
  --key-name harish-KP \
  --security-group-ids $SG_ID \
  --iam-instance-profile Name=jenkins-sprint1-instance-profile \
  --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=30,VolumeType=gp3}" \
  --region ap-south-1 \
  --query 'Instances[0].InstanceId' \
  --output text)

--Get AMI_ID:

aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images[0].ImageId' \
  --region ap-south-1 \
  --output text


INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.medium \
  --key-name capstone-project-KP \
  --security-group-ids $SG_ID \
  --iam-instance-profile Name=jenkins-sprint1-instance-profile \
  --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=30,VolumeType=gp3}" \
  --region ap-south-1 \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"

# Wait for instance to be running
aws ec2 wait instance-running \
  --instance-ids $INSTANCE_ID \
  --region ap-south-1

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --region ap-south-1)

echo "Public IP: $PUBLIC_IP"
```

### 4.2 Wait for Instance to Be Running

```bash
# Check instance status
aws ec2 describe-instance-status \
  --instance-ids $INSTANCE_ID \
  --region ap-south-1
```

Wait 2-3 minutes for the instance to reach "running" state with status checks passing.

### 4.3 SSH into the Instance

```bash
# Replace the key and IP
ssh -i /path/to/your-key.pem ubuntu@<PUBLIC_IP>
# OR for Amazon Linux:
ssh -i /path/to/your-key.pem ec2-user@<PUBLIC_IP>
```

---

## Step 5: Install Jenkins and Dependencies

### 5.1 Bootstrap Script (Ubuntu 24.04 / 22.04)

Once SSH'd into the EC2 instance, run the following bootstrap script:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "====== Jenkins EC2 Bootstrap Started ======"

# Update system
echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release wget unzip git

# Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

# Install AWS CLI v2
echo "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install Java 21
echo "Installing Java 21..."
sudo apt install -y openjdk-21-jre-headless

# Install Jenkins
echo "Installing Jenkins..."
# Install GnuPG and CA certificates (for Jenkins repo key import)
sudo apt install -y gnupg ca-certificates
# Create keyring directory and import Jenkins GPG key
sudo mkdir -p /usr/share/keyrings
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/jenkins-keyring.gpg \
  --keyserver hkps://keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68
# Add Jenkins repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
# Update package lists after adding repository
sudo apt update
# Install Jenkins
sudo apt install -y jenkins

# Set JAVA_HOME for Jenkins
echo "Configuring Jenkins..."
sudo mkdir -p /etc/systemd/system/jenkins.service.d
cat <<EOF | sudo tee /etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
EOF

# Start Jenkins
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to start..."
sleep 10

# Verify installations
echo ""
echo "====== Installation Verification ======"
echo "Docker version:"
docker --version
echo ""
echo "AWS CLI version:"
aws --version
echo ""
echo "Java version:"
java -version
echo ""
echo "Git version:"
git --version
echo ""
echo "Jenkins status:"
sudo systemctl status jenkins --no-pager

# Get Jenkins admin password
echo ""
echo "====== Jenkins Admin Password ======"
sleep 5
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
  echo "Save this password to unlock Jenkins:"
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
else
  echo "Password file not ready yet. Retrieve it with:"
  echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi

echo ""
echo "====== Bootstrap Complete ======"
echo "Access Jenkins at: http://<EC2_PUBLIC_IP>:8080"
```

### 5.2 Run Bootstrap Script

Copy the script above, save it to a file (e.g., `bootstrap.sh`), then run:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

Or run commands directly one by one if you prefer more control.

### GPG NO_PUBKEY Fix (if apt reports NO_PUBKEY for Jenkins)

If `sudo apt update` shows a NO_PUBKEY error for the Jenkins repo, run these exact commands on the EC2 instance to import the Jenkins signing key and update apt:

```bash
sudo apt install -y gnupg ca-certificates
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/jenkins-keyring.gpg \
  --keyserver hkps://keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68
sudo apt update
```


### 5.3 Verify All Services Are Running

After bootstrap completes, verify:

```bash
# Docker
docker --version
docker ps

# AWS CLI
aws --version
aws sts get-caller-identity

# Java
java -version

# Git
git --version

# Jenkins
sudo systemctl status jenkins
```

All commands should succeed without errors.

---

## Step 6: Configure Jenkins

### 6.1 Access Jenkins Web UI

1. Note the EC2 public IP address
2. Open a browser and navigate to: `http://<EC2_PUBLIC_IP>:8080`
3. You should see the Jenkins unlock page

# Install Jenkins
echo "Installing Jenkins..."
# 1. Install Java (required for Jenkins)
sudo apt install -y openjdk-17-jdk

# 2. Install GnuPG and CA certificates (for key import)
sudo apt install -y gnupg ca-certificates

# 3. Create keyring directory and import Jenkins GPG key
sudo mkdir -p /usr/share/keyrings
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/jenkins-keyring.gpg \
  --keyserver hkps://keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68

# 4. Add Jenkins repository (signed-by the imported key)
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# 5. Update package lists
sudo apt update

# 6. Install Jenkins
sudo apt install -y jenkins

# 7. Enable and start Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins || true
1. Navigate to **Manage Jenkins** → **Manage Plugins**
2. Go to the **Available** tab
3. Search for and install the following plugins:
   - **Pipeline** (workflow-aggregator)
   - **Git Plugin**
   - **Docker Pipeline**
   - **Credentials Binding**
   - **AWS Steps** (optional but recommended)
   - **Amazon ECR** (optional)
   - **Blue Ocean** (optional, for better UI)

4. Check the checkboxes for each plugin and click **Install without restart**
5. Wait for installations to complete, then click **Go back to the top page**

**Note**: If you need to restart Jenkins:
```bash
sudo systemctl restart jenkins
```

### 6.7 Configure Jenkins System Settings

1. Navigate to **Manage Jenkins** → **Configure System**
2. Set **# of executors**: 4 (or based on instance type)
3. Leave other settings as defaults
4. Click **Save**

---

## Step 7: Set Up Git Integration

### 7.1 Create Git Credentials in Jenkins (If Using Private Repository)

If your repository is **public**, skip to Step 8.

If your repository is **private**, add credentials:

1. Navigate to **Manage Jenkins** → **Manage Credentials**
2. Click the **(global)** domain
3. Click **Add Credentials**
4. Choose credential type:
   - **Username with password**: For HTTPS
   - **SSH Username with private key**: For SSH
5. Fill in the details:
   - **Username**: Your GitHub/GitLab username or `git`
   - **Password/SSH Key**: Your personal access token or SSH key
   - **ID**: `git-sprint1-creds`
   - **Description**: `Git credentials for Sprint 1`
6. Click **Create**

### 7.2 Generate GitHub Personal Access Token (if using GitHub HTTPS)

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens**
2. Click **Generate new token (classic)**
3. Give it a name: `jenkins-sprint1`
4. Select scopes: `repo` (full control of private repositories)
5. Click **Generate token**
6. Copy the token and use it as the password in Jenkins credentials

### 7.3 Add SSH Key to Jenkins (if using SSH)

1. Generate an SSH key pair locally or on the EC2:

```bash
ssh-keygen -t ed25519 -C "jenkins-sprint1" -f ~/.ssh/jenkins_key -N ""
cat ~/.ssh/jenkins_key.pub
```

2. Add the public key to your Git repository (GitHub/GitLab):
   - GitHub: Settings → Deploy keys → Add deploy key
   - GitLab: Settings → Repository → Deploy keys

3. In Jenkins, create SSH credentials with the private key content

---

## Step 8: Create and Test Jenkins Pipeline Job

### 8.1 Create New Pipeline Job

1. Click **New Item** on Jenkins home page
2. Enter job name: `web-app-sprint1-pipeline`
3. Select **Pipeline** as the job type
4. Click **OK**

### 8.2 Configure Pipeline Source

1. Scroll to **Pipeline** section
2. Select **Definition**: `Pipeline script from SCM`
3. Choose **SCM**: `Git`
4. Enter:
   - **Repository URL**: Your Git repository URL (e.g., `https://github.com/your-org/webapp-pipeline-e2e.git`)
   - **Credentials**: Select your Git credentials (or leave empty for public repos)
   - **Branch Specifier**: `*/main` (or your branch name)
   - **Script Path**: `Web-app-pipeline-e2e/Jenkinsfile`

### 8.3 Update Jenkinsfile with Your AWS Details

Edit the file [Web-app-pipeline-e2e/Jenkinsfile](Web-app-pipeline-e2e/Jenkinsfile):

```groovy
environment {
    AWS_REGION = 'ap-south-1'                    # Change to your region
    AWS_ACCOUNT_ID = '234951664603'               # Change to your AWS account ID
    ECR_REPO_NAME = 'web-app-sprint1'             # Keep or change repo name
    IMAGE_TAG = "${env.BUILD_ID}"
    IMAGE_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}"
}
```

### 8.4 Configure Build Triggers (Optional)

1. Scroll to **Build Triggers** section
2. Choose one or more:
   - **GitHub hook trigger for GITScm polling**: (if using GitHub with webhook)
   - **Poll SCM**: Use cron-like syntax (e.g., `H/5 * * * *` for every 5 minutes)
   - **Trigger builds remotely**: Requires a token

**Recommended**: Use GitHub webhook for immediate triggers:
- GitHub repo → Settings → Webhooks → Add webhook
- Payload URL: `http://<JENKINS_IP>:8080/github-webhook/`
- Content type: `application/json`
- Events: `Just the push event`

### 8.5 Save Job Configuration

Click **Save**

---

## Step 9: Validate End-to-End Pipeline

### 9.1 Trigger a Manual Build

1. On the Jenkins job page, click **Build Now**
2. In the **Build History** section, click the build number (e.g., #1)
3. Click **Console Output** to watch the build progress
4. Expected output:

```
Started by user admin
Running in Docker container abc123...

====== Stage: Checkout ======
Checking out from repository...

====== Stage: Validate AWS Access ======
{
    "UserId": "...",
    "Account": "234951664603",
    "Arn": "arn:aws:sts::..."
}

====== Stage: Build Docker Image ======
docker build -t web-app-sprint1:123 .
Successfully built abc123...
Successfully tagged web-app-sprint1:123

====== Stage: Login to ECR ======
WARNING! Your password will be stored unencrypted...
Login Succeeded

====== Stage: Push to ECR ======
The push refers to repository [234951664603.dkr.ecr.ap-south-1.amazonaws.com/web-app-sprint1]
123: digest: sha256:... size: 1234

====== Build Successful ======
```

### 9.2 Verify Image in ECR

1. Navigate to AWS ECR → Repositories → `web-app-sprint1`
2. Verify the new image tag is present (e.g., `123`)
3. Click the image to view details (digest, size, scan results)

### 9.3 Test Git Webhook Integration

1. Make a small change to the repository (e.g., update README.md)
2. Commit and push to the main branch:

```bash
git add -A
git commit -m "Test Jenkins webhook trigger"
git push origin main
```

3. Within 30 seconds, Jenkins should automatically trigger a new build
4. Verify the build runs automatically in Jenkins

### 9.4 Verify Docker Image Runs

1. On the Jenkins EC2 instance, pull and run the image:

```bash
# Pull the image from ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin 234951664603.dkr.ecr.ap-south-1.amazonaws.com

docker pull 234951664603.dkr.ecr.ap-south-1.amazonaws.com/web-app-sprint1:123

# Run the image
docker run -p 3000:3000 234951664603.dkr.ecr.ap-south-1.amazonaws.com/web-app-sprint1:123
```

2. Test the application:

```bash
# From another terminal on the EC2 or your local machine
curl http://<JENKINS_EC2_IP>:3000
```

Expected response:
```
Sprint 1 Web Application - CI/CD Pipeline Ready
```

---

## Troubleshooting

### Issue: Jenkins Won't Start

**Symptoms**: Jenkins URL returns 503 or connection refused.

**Solutions**:

1. Check Jenkins service status:
```bash
sudo systemctl status jenkins
sudo journalctl -u jenkins -n 50 --no-pager
```

2. Verify Java is installed:
```bash
java -version
```

3. Restart Jenkins:
```bash
sudo systemctl restart jenkins
```

4. Check available disk space:
```bash
df -h
```

### Issue: Docker Build Fails

**Symptoms**: Build stage shows "docker: command not found" or Docker build fails.

**Solutions**:

1. Verify Docker is installed:
```bash
docker --version
docker ps
```

2. Verify Jenkins user is in docker group:
```bash
groups jenkins
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

3. Check Docker daemon is running:
```bash
sudo systemctl start docker
sudo systemctl status docker
```

### Issue: AWS Access Denied

**Symptoms**: "ValidateAWSAccess" stage shows access denied errors or credential errors.

**Solutions**:

1. Verify IAM role is attached to EC2:
```bash
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
# Should return the role name
```

2. Verify IAM role has correct permissions:
```bash
aws sts get-caller-identity
aws ecr describe-repositories --region ap-south-1
```

3. If using stored credentials, verify they're added to Jenkins:
   - Jenkins → Credentials → (global) → Should see credentials listed

### Issue: ECR Login Fails

**Symptoms**: "Login to ECR" stage fails with "no basic auth credentials".

**Solutions**:

1. Verify ECR repository exists:
```bash
aws ecr describe-repositories \
  --repository-names web-app-sprint1 \
  --region ap-south-1
```

2. Verify IAM permissions include ECR:
```bash
aws ecr get-authorization-token --region ap-south-1
```

3. Test login manually:
```bash
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  234951664603.dkr.ecr.ap-south-1.amazonaws.com
```

### Issue: Git Repository Not Found

**Symptoms**: Checkout stage fails with "Repository not found".

**Solutions**:

1. Verify repository URL is correct:
   - For HTTPS: `https://github.com/your-org/webapp-pipeline-e2e.git`
   - For SSH: `git@github.com:your-org/webapp-pipeline-e2e.git`

2. If private repo, verify Git credentials are added:
   - Jenkins → Credentials → (global) → Should see Git credentials

3. Test Git access locally:
```bash
git clone <your-repo-url>
```

### Issue: Pipeline Runs But Image Not Pushed to ECR

**Symptoms**: Build succeeds, but image doesn't appear in ECR.

**Solutions**:

1. Verify ECR repository is correct in Jenkinsfile:
   - Compare with ECR console URI

2. Check Jenkins console output for "Push to ECR" stage:
   - Verify no error messages

3. Manually verify image exists locally:
```bash
docker images | grep web-app-sprint1
```

4. Manually push image:
```bash
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  234951664603.dkr.ecr.ap-south-1.amazonaws.com

docker tag web-app-sprint1:123 \
  234951664603.dkr.ecr.ap-south-1.amazonaws.com/web-app-sprint1:123

docker push \
  234951664603.dkr.ecr.ap-south-1.amazonaws.com/web-app-sprint1:123
```

### Issue: Port 8080 Not Accessible

**Symptoms**: Cannot reach Jenkins at `http://<IP>:8080`.

**Solutions**:

1. Verify security group allows port 8080:
```bash
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx \
  --region ap-south-1
```

2. Add inbound rule if missing:
```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0 \
  --region ap-south-1
```

3. Verify Jenkins is listening:
```bash
sudo netstat -tulpn | grep 8080
# or
sudo ss -tulpn | grep 8080
```

4. Check firewall rules on instance (if using UFW):
```bash
sudo ufw allow 8080/tcp
sudo ufw status
```

---

## Next Steps (Future Sprints)

After completing Sprint 1, you have:
- ✅ Designed the application architecture
- ✅ Dockerized the web application
- ✅ Set up Jenkins on AWS EC2
- ✅ Configured AWS access via IAM roles
- ✅ Integrated Git with Jenkins
- ✅ Automated Docker builds and ECR pushes

**Sprint 2** will add:
- AWS infrastructure provisioning (VPC, subnets, EKS cluster)
- Terraform IaC for reproducible deployments
- Auto-scaling configuration

**Sprint 3** will add:
- Ansible configuration management
- Automated instance provisioning

**Sprint 4** will add:
- Kubernetes deployments to EKS
- Helm charts for release management

**Sprint 5** will add:
- Prometheus and Grafana monitoring
- Log aggregation (CloudWatch / ELK)
- Alert management

---

## Additional References

- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [Docker Official Documentation](https://docs.docker.com/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Jenkinsfile Syntax Reference](https://www.jenkins.io/doc/book/pipeline/syntax/)

---

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Consult the references above
3. Review the logs in Jenkins console output
4. Check EC2 instance system logs in AWS console

---

**Last Updated**: May 2026  
**Sprint**: Sprint 1 - Architecture Design, Dockerization, and Jenkins Setup  
**Status**: Complete and tested
