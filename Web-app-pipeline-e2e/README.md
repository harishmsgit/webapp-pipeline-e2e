# End-to-End DevOps Pipeline for a Web Application with CI/CD

## Sprint 1: Architecture Design, Dockerization, and Jenkins Setup

This repository contains a complete, production-ready implementation of **Sprint 1** of a multi-sprint DevOps pipeline project. The goal is to establish a robust CI/CD foundation using Docker, AWS ECR, and Jenkins running on AWS EC2.

### 📋 Sprint 1 Objectives

✅ **Design the application architecture** for deployment on AWS EKS  
✅ **Dockerize the web application** with a working Dockerfile  
✅ **Set up Jenkins server** on AWS EC2 with necessary plugins  
✅ **Configure AWS access** using IAM roles and credentials  
✅ **Set up Git integration** for automated CI/CD triggers  

### ✨ What is Included

- **Application**: Lightweight Node.js web application (see `app/`)
- **Containerization**: Dockerfile and docker-compose.yml for local testing
- **CI/CD Pipeline**: Jenkinsfile with automated build and push to AWS ECR
- **Documentation**: Complete setup guide and architecture design
- **IAM Policies**: JSON policy templates for AWS access control
- **Bootstrap Scripts**: Automated EC2 setup with all dependencies

### ❌ What is Intentionally Excluded

- AWS infrastructure provisioning (VPC, EKS, subnets) — scheduled for Sprint 2
- Kubernetes deployments to EKS — scheduled for Sprint 4
- Terraform infrastructure-as-code — scheduled for Sprint 2
- Ansible configuration management — scheduled for Sprint 3
- Prometheus/Grafana monitoring — scheduled for Sprint 5

## Sprint 2: Terraform Infrastructure Provisioning

This project now includes Sprint 2 infrastructure automation for AWS with Terraform and Jenkins integration. The new assets automate provisioning of:

- VPC, public subnets, Internet Gateway, and route table
- EKS cluster and managed node group
- EC2 management instance and security groups
- Terraform state storage in AWS S3 with DynamoDB locking
- Jenkins pipeline support for automated Terraform provisioning

New files for Sprint 2:

- `terraform/` — Terraform configuration for AWS infrastructure
- `Jenkinsfile.terraform` — Jenkins pipeline definition for Terraform plan/apply
- `SPRINT2_SETUP_GUIDE.md` — Instructions for Terraform provisioning and Jenkins job setup
- `doc/jenkins-terraform-job.md` — Detailed Jenkins job creation and Job DSL example
- Feature branch: `feature/sprint2-terraform`

## Sprint 4: CI/CD Deployment to EKS

Sprint 4 adds full application delivery from source to Kubernetes on AWS EKS. The new pipeline builds the Docker image, pushes it to Amazon ECR, and deploys the app into EKS with readiness/liveness probes and autoscaling.

New files for Sprint 4:

- `Jenkinsfile.sprint4` — Jenkins pipeline for application build, test, Docker/ECR push, and EKS deployment
- `app/Dockerfile` — application container build instructions
- `app/test.js` — lightweight smoke test for the Node.js app
- `app/.dockerignore` — Docker ignore rules for the app image
- `k8s/namespace.yaml` — Kubernetes namespace manifest
- `k8s/deployment.yaml` — Kubernetes Deployment with health checks
- `k8s/service.yaml` — Kubernetes Service for external access
- `k8s/hpa.yaml` — Kubernetes HorizontalPodAutoscaler for CPU-based scaling

### Sprint 4 Deployment Notes

- The `Jenkinsfile.sprint4` pipeline expects a Jenkins agent with `docker`, `aws`, and `kubectl` installed.
- The pipeline builds the image in `app/`, pushes it to ECR, and then deploys the Kubernetes manifests to the target EKS cluster.
- If the requested image tag already exists in ECR, the pipeline skips the push step and continues to deploy the existing image.
- The manifest `k8s/deployment.yaml` contains a placeholder image value that is replaced at deploy time with the pushed ECR image URI.

### Jenkins Parameters for `Jenkinsfile.sprint4`

- `AWS_REGION` — AWS region to use (default: `ap-south-1`)
- `AWS_ACCOUNT_ID` — required AWS account ID for the ECR repository
- `ECR_REPO_NAME` — ECR repository name (default: `web-app-sprint4`)
- `IMAGE_TAG` — optional tag; defaults to Jenkins `BUILD_ID`
- `EKS_CLUSTER_NAME` — required EKS cluster name
- `K8S_NAMESPACE` — Kubernetes namespace to deploy into (default: `webapp`)
- `RUN_DEPLOYMENT` — whether to deploy after image push (default: `true`)

### Quick Sprint 4 Run

1. Create a Jenkins pipeline job using `Jenkinsfile.sprint4` from SCM.
2. Provide `AWS_ACCOUNT_ID` and `EKS_CLUSTER_NAME` in the job parameters.
3. Run the job to build, test, push to ECR, and deploy to Kubernetes.
4. Verify the deployment with `kubectl get all -n webapp` and `kubectl get hpa -n webapp`.

## 📂 Directory Structure

```
Web-app-pipeline-e2e/
├── SPRINT1_SETUP_GUIDE.md          # ⭐ Start here: Complete step-by-step setup guide
├── README.md                        # This file
├── Dockerfile                       # Docker image build instructions
├── docker-compose.yml               # Local testing with Docker Compose
├── Jenkinsfile                      # Jenkins CI/CD pipeline definition
├── Jenkinsfile.terraform            # Jenkins pipeline for Terraform infrastructure provisioning
├── SPRINT2_SETUP_GUIDE.md           # Sprint 2 Terraform and Jenkins integration guide
├── jenkins-ecr-policy.json          # AWS IAM policy for ECR access
│
├── app/
│   ├── server.js                    # Node.js web application
│   └── package.json                 # Node.js dependencies
│
├── terraform/                      # Terraform modules for AWS VPC, EKS, EC2, and state backend
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   └── versions.tf
│
└── doc/
    ├── architecture-sprint1.md      # Architecture design and AWS integration plan
    ├── jenkins-setup.md             # Jenkins configuration details
    ├── jenkins-conf-pipeline-creation-ec2.md  # EC2 and pipeline job setup
    ├── jenkins-init-plugins-creds.groovy     # Automated plugin installation script
    └── aws/                         # Additional AWS documentation
```

## 🚀 Quick Start

### Prerequisites

- Docker installed locally
- Git installed
- AWS account with appropriate IAM permissions
- AWS CLI v2 installed (optional, for AWS operations)

### 1️⃣ Local Validation (5 minutes)

Test the application and Docker build on your local machine:

```bash
# Clone the repository
git clone <your-repo-url>
cd Web-app-pipeline-e2e

# Install Node.js dependencies
npm install

# Run the application locally
node app/server.js
# Output: Server running on port 3000

# In another terminal, test the application
curl http://localhost:3000
# Output: Sprint 1 Web Application - CI/CD Pipeline Ready

# Build Docker image
docker build -t web-app-sprint1:latest .

# Run Docker image
docker run -p 3000:3000 web-app-sprint1:latest

# Test with Docker Compose
docker compose up --build
# Access at http://localhost:3000
```

### 2️⃣ AWS Setup (10 minutes)

Create AWS resources for Jenkins and ECR:

```bash
# Set your region and account ID
export AWS_REGION="ap-south-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create IAM role for Jenkins EC2
aws iam create-role \
  --role-name jenkins-sprint1-ec2-role \
  --assume-role-policy-document file://jenkins-trust-policy.json \
  --region $AWS_REGION

# Create ECR repository
aws ecr create-repository \
  --repository-name web-app-sprint1 \
  --region $AWS_REGION \
  --image-tag-mutability ENABLE

# Get ECR repository URI
aws ecr describe-repositories \
  --repository-names web-app-sprint1 \
  --region $AWS_REGION \
  --query 'repositories[0].repositoryUri' \
  --output text
```

### 3️⃣ Jenkins Setup (15-20 minutes)

Follow the [SPRINT1_SETUP_GUIDE.md](SPRINT1_SETUP_GUIDE.md) for complete step-by-step instructions:

- Launch EC2 instance
- Install Jenkins, Docker, and AWS CLI
- Configure Jenkins plugins
- Create pipeline job from this repository
- Test the CI/CD pipeline

## 📖 Documentation

| Document | Purpose | Duration |
|----------|---------|----------|
| **[SPRINT1_SETUP_GUIDE.md](SPRINT1_SETUP_GUIDE.md)** | Complete setup guide with all steps | 30-45 min |
| [doc/architecture-sprint1.md](doc/architecture-sprint1.md) | Architecture design and AWS overview | 5-10 min |
| [doc/jenkins-setup.md](doc/jenkins-setup.md) | Jenkins installation and configuration | 10-15 min |
| [doc/jenkins-conf-pipeline-creation-ec2.md](doc/jenkins-conf-pipeline-creation-ec2.md) | EC2 bootstrap and pipeline job setup | 10-15 min |

## 🔄 Pipeline Overview

The Jenkins pipeline automates the following workflow:

```
Code Push to Git
      ↓
Jenkins Detects Change (webhook or poll)
      ↓
Checkout Source Code
      ↓
Validate AWS Access & Credentials
      ↓
Build Docker Image
      ↓
Authenticate to AWS ECR
      ↓
Create ECR Repository (if needed)
      ↓
Tag and Push Docker Image to ECR
      ↓
Verify Image in ECR
      ↓
✅ Pipeline Success
```

## 🧪 Validation Steps

After setup, validate the end-to-end pipeline:

```bash
# 1. Make a code change
echo "# Updated" >> README.md

# 2. Commit and push
git add -A
git commit -m "Test Jenkins trigger"
git push origin main

# 3. Observe Jenkins automatically triggering build
# Jenkins console should show build progress

# 4. Verify image in ECR
aws ecr describe-images \
  --repository-name web-app-sprint1 \
  --region ap-south-1

# 5. Pull and run the image
docker pull $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/web-app-sprint1:latest
docker run -p 3000:3000 $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/web-app-sprint1:latest

# 6. Test the application
curl http://localhost:3000
```

## 🔐 Security Considerations

- **IAM Roles**: Use EC2 instance IAM roles (preferred) instead of stored credentials
- **ECR Permissions**: The Jenkins credentials must allow ECR login and push operations. See `jenkins-ecr-policy.json` for the required actions.
- **Security Groups**: Restrict SSH (22) and Jenkins UI (8080) to your IP
- **Git Credentials**: Use personal access tokens or SSH keys, not passwords
- **ECR Scanning**: Enable image scanning on push to detect vulnerabilities
- **Logging**: Enable CloudTrail and VPC Flow Logs for audit trails

## 🐛 Troubleshooting

Refer to the [SPRINT1_SETUP_GUIDE.md](SPRINT1_SETUP_GUIDE.md#troubleshooting) section for solutions to common issues:

- Jenkins won't start
- Docker build fails
- AWS access denied
- ECR login fails
- Git repository not found
- Pipeline runs but image not pushed

## 📝 Configuration

### Update Jenkinsfile with Your AWS Details

Edit [Jenkinsfile](Jenkinsfile) to use your AWS account and region:

```groovy
environment {
    AWS_REGION = 'ap-south-1'              # Your AWS region
    AWS_ACCOUNT_ID = '123456789012'        # Your AWS account ID
    ECR_REPO_NAME = 'web-app-sprint1'      # Your ECR repository name
}
```

### Update docker-compose.yml for Your Needs

Edit [docker-compose.yml](docker-compose.yml) to change ports or environment:

```yaml
services:
  web:
    build: .
    ports:
      - "3000:3000"  # Change host port as needed
    environment:
      - NODE_ENV=production
```

## 📊 Metrics and Monitoring

After Sprint 1 setup, track these metrics:

- **Build Success Rate**: Percentage of successful builds
- **Build Time**: Average time to build and push image
- **Image Size**: Docker image size in MB/GB
- **ECR Push Frequency**: Number of images pushed per day
- **Pipeline Reliability**: Uptime and error rates

## 🔄 Next Steps

After completing Sprint 1:

- **Sprint 2**: Provision AWS infrastructure (VPC, EKS cluster) with Terraform
- **Sprint 3**: Add Ansible automation for configuration management
- **Sprint 4**: Deploy application to EKS and set up auto-scaling
- **Sprint 5**: Add monitoring (Prometheus, Grafana) and alerting

## 📞 Support

For issues or questions:

1. Review the [Troubleshooting](SPRINT1_SETUP_GUIDE.md#troubleshooting) section
2. Check Jenkins console output for detailed error messages
3. Review AWS CloudTrail logs for API errors
4. Consult the [Additional References](SPRINT1_SETUP_GUIDE.md#additional-references)

## 📄 License

This project is provided as-is for educational and enterprise use.

---

**Status**: ✅ Complete and Tested  
**Last Updated**: May 2026  
**Sprint**: Sprint 1 - Architecture Design, Dockerization, and Jenkins Setup  
**Maintainer**: DevOps Team

**Start with [SPRINT1_SETUP_GUIDE.md](SPRINT1_SETUP_GUIDE.md) for complete setup instructions!**




aws ecr describe-repositories --repository-names web-app-sprint4 --region ap-south-1

aws ecr get-login-password --region ap-south-1 \
| docker login --username BtnHurryPot@26 --password-stdin 495013583028.dkr.ecr.ap-south-1.amazonaws.com





aws iam create-policy --policy-name jenkins-ecr-policy --policy-document file://jenkins-ecr-policy.json


aws iam attach-role-policy \
  --role-name jenkins-sprint1-ec2-role \
  --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/jenkins-ecr-policy


  aws iam attach-user-policy \
  --user-name jenkins-user \
  --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/jenkins-ecr-policy


  aws iam put-role-policy \
  --role-name jenkins-sprint1-ec2-role \
  --policy-name JenkinsECRPushPolicy \
  --policy-document file://jenkins-ecr-policy.json