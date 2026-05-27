# End-to-End DevOps Pipeline for a Web Application with CI/CD

## Sprint 1 Deliverables

This workspace implements only Sprint 1: Architecture Design, Dockerization, and Jenkins Setup.

### What is included
- Application architecture design for AWS-based deployment
- Dockerized web application with a working `Dockerfile`
- Jenkins pipeline definition in `Jenkinsfile`
- Jenkins setup guidance for AWS EC2, required plugins, and AWS/EKS access
- Git integration details for CI triggers

### What is intentionally excluded
- AWS infrastructure provisioning with Terraform
- Kubernetes deployments to EKS
- Ansible automation
- Prometheus / Grafana monitoring
- Production deployment workflows beyond Sprint 1

## Directory structure

- `app/`
  - `server.js` — lightweight Node.js web application
  - `package.json` — app metadata and start script
- `Dockerfile` — Docker image build instructions
- `Jenkinsfile` — Jenkins declarative pipeline for Sprint 1
- `architecture-sprint1.md` — architecture design and AWS integration plan
- `jenkins-setup.md` — Jenkins setup and plugin configuration
- `.gitignore` — ignores node artifacts

## Local validation

1. Build locally:
   ```sh
   docker build -t web-app-sprint1:latest .
   ```
2. Run locally:
   ```sh
   docker run -p 3000:3000 web-app-sprint1:latest
   ```
3. Validate with Docker Compose:
   ```sh
   docker compose config
   docker compose up --build
   ```
4. Open `http://localhost:3000`

## Jenkins usage

1. Create a Jenkins freestyle or pipeline job.
2. Point it to this repository.
3. Use the `Jenkinsfile` to execute the Sprint 1 CI pipeline.
4. Configure AWS credentials and Git access as described in `jenkins-setup.md`.

## Notes

Sprint 1 focuses on establishing the foundation for CI/CD: architecture design, containerization, and Jenkins server integration. Future sprints will build on this foundation to provision AWS infrastructure and deploy to EKS.
