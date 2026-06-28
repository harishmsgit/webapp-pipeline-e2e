# Sprint 4 — CI/CD Pipeline for Application Deployment on Kubernetes (EKS)

## Overview
This file summarizes the Sprint 4 changes made in this repository, and provides recommended steps to run and validate the end-to-end pipeline that builds, tests, publishes a Docker image to AWS ECR and deploys to an EKS cluster.

## What changed (files added / modified)
- `Jenkinsfile.sprint4` — New multi-stage Jenkins pipeline for application build, test, Docker build, ECR push, and EKS deployment.
- `k8s/namespace.yaml` — Namespace for application deployment.
- `k8s/deployment.yaml` — Application Deployment with readiness and liveness probes and resource requests/limits.
- `k8s/service.yaml` — LoadBalancer Service exposing the application.
- `k8s/hpa.yaml` — Horizontal Pod Autoscaler (CPU utilization based).
- `app/Dockerfile` — Container build for the Node.js application.
- `app/.dockerignore` — Docker ignore rules.
- `app/test.js` — Lightweight smoke test used by `npm test`.
- `README.md` — Sprint 4 documentation and quick-run instructions.

## Purpose
Implement a fully automated CI/CD pipeline that:
- Builds and tests the Node.js application
- Builds a Docker image and pushes it to AWS ECR
- Updates an EKS cluster by applying Kubernetes manifests
- Configures health checks and autoscaling

## Requirements / Assumptions
- Jenkins agent has `docker`, `kubectl`, `aws` CLI available and configured
- AWS credentials available in Jenkins (via credentials binding or instance role)
- EKS cluster already provisioned and accessible (e.g., via Terraform in `terraform/`)
- ECR repository will be created by the pipeline if missing

## Run/Validation Steps
1. Create a Jenkins pipeline job that uses `Jenkinsfile.sprint4` from this repo's branch `feature/sprint4-EKS-ECR-Multi-Stage`.
2. Provide these job parameters (or set as defaults/credentials in Jenkins):
   - `AWS_REGION` (default: `ap-south-1`)
   - `AWS_ACCOUNT_ID` (required)
   - `ECR_REPO_NAME` (default: `web-app-sprint4`)
   - `EKS_CLUSTER_NAME` (required)
   - `K8S_NAMESPACE` (default: `webapp`)
3. Run the job. The pipeline will:
   - Checkout source
   - Run `npm install` and `npm test` in `app/`
   - Build Docker image and tag with `${IMAGE_TAG}` and `latest`
   - Login to ECR and push images
   - Update kubeconfig and deploy Kubernetes manifests to the cluster
   - Wait for rollout and report HPA state
4. Validate deployment:
```bash
kubectl get all -n webapp
kubectl get hpa -n webapp
kubectl logs -l app=webapp -n webapp --tail=100
```

## Rollback
- To rollback to previous image tag, run:
```bash
kubectl set image deployment/webapp webapp=<previous-image-uri> -n webapp
kubectl rollout status deployment/webapp -n webapp
```

## Next improvements (optional)
- Add automated integration tests (E2E) post-deploy
- Add image vulnerability scanning (e.g., using ECR scan or Trivy in pipeline)
- Use immutable tags and Git SHA tags for reproducible deployments
- Add GitHub Actions or Azure Pipelines alternative for redundancy

## Contact / Maintainers
- Repo owner: Harish
- Branch for Sprint 4 work: `feature/sprint4-EKS-ECR-Multi-Stage`

# Sprint 4 — CI/CD Pipeline (EKS + ECR)

Date: 2026-06-28

Summary
-------
This sprint adds a complete application CI/CD flow that builds a Docker image, pushes it to AWS ECR, and deploys the application to AWS EKS with health checks and autoscaling.

Files added or changed
----------------------
- `Jenkinsfile.sprint4` — multi-stage Jenkins pipeline (checkout, build, test, docker build, push to ECR, deploy to EKS)
- `k8s/namespace.yaml` — Kubernetes Namespace
- `k8s/deployment.yaml` — Deployment with readiness/liveness probes (placeholder image replaced at deploy)
- `k8s/service.yaml` — LoadBalancer Service
- `k8s/hpa.yaml` — HorizontalPodAutoscaler (CPU target)
- `app/Dockerfile` — container build
- `app/.dockerignore`
- `app/test.js` — lightweight smoke test invoked by `npm test`
- `README.md` — documented Sprint 4 usage and parameters

Goal
----
Build a fully automated Jenkins pipeline that takes code → builds image → pushes to ECR → deploys to EKS (with health checks and autoscaling).

Prerequisites
-------------
- An EKS cluster already provisioned and accessible.
- AWS account with ECR/EKS permissions for the Jenkins agent (prefer instance profile or Jenkins credential with limited IAM policies).
- Jenkins agent that has `docker`, `aws` CLI v2, and `kubectl` installed and configured.
- Jenkins credentials: AWS credentials (or instance role) and any SSH keys if using Ansible management jobs.

Jenkins job parameters (recommended)
-----------------------------------
- `AWS_REGION` — e.g. `ap-south-1`
- `AWS_ACCOUNT_ID` — your AWS account ID (required)
- `ECR_REPO_NAME` — default: `web-app-sprint4`
- `IMAGE_TAG` — optional; defaults to Jenkins `BUILD_ID`
- `EKS_CLUSTER_NAME` — EKS cluster name (required)
- `K8S_NAMESPACE` — default: `webapp`
- `RUN_DEPLOYMENT` — toggle deployment after push (default: `true`)

How to run (quick)
------------------
1. Create a Jenkins pipeline job using `Jenkinsfile.sprint4` from this branch.
2. Provide `AWS_ACCOUNT_ID` and `EKS_CLUSTER_NAME` when running the job.
3. Start the job; it will:
   - install app deps and run `npm test` (via `app/test.js`)
   - build Docker image and tag as `${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}`
   - push image to ECR
   - update kubeconfig and deploy Kubernetes manifests (namespace, deployment, service, HPA)

Manual deploy example (local)
----------------------------
Build, tag, push (replace variables):

```bash
# local example
export AWS_REGION=ap-south-1
export AWS_ACCOUNT_ID=123456789012
export ECR_REPO_NAME=web-app-sprint4
export IMAGE_TAG=localtest

docker build -t ${ECR_REPO_NAME}:${IMAGE_TAG} -f app/Dockerfile .
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION} || true
docker tag ${ECR_REPO_NAME}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}

# Deploy to EKS
aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
sed 's|REPLACE_IMAGE|${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}|g' k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl rollout status deployment/webapp -n ${K8S_NAMESPACE} --timeout=120s
```

Verification
------------
- `kubectl get all -n webapp`
- `kubectl get hpa -n webapp`
- Run `./scripts/check_post_deploy.sh` with `NAMESPACE=webapp APP_LABEL=webapp SERVICE=webapp` to produce a verification report.

Rollback
--------
- `kubectl rollout undo deployment/webapp -n webapp`

Troubleshooting notes
---------------------
- Image pull errors: ensure ECR repo and image tag exist and that worker nodes have ECR access (IAM). Node IAM role should include `AmazonEC2ContainerRegistryReadOnly`.
- `aws eks update-kubeconfig` failing: verify Jenkins agent IAM or credentials can call `eks:DescribeCluster`.
- `ImagePullBackOff`: check ECR permissions and image tag.

Next steps
----------
- Create a Jenkins job in the real Jenkins server (or configure the existing CI to use `Jenkinsfile.sprint4`).
- Add secret credentials to Jenkins (AWS credentials ID) and update job parameters.
- Optionally add integration tests and monitoring alerts.

Contact
-------
If anything needs changing in this file or the pipeline, open a PR on branch `feature/sprint4-EKS-ECR-Multi-Stage` or ask here.
