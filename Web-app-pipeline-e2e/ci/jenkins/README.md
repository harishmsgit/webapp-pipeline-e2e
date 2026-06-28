# Jenkins job: seed instructions for Sprint 4 pipeline

Files added:
- `ci/jenkins/sprint4_job.groovy` — Job DSL that creates job `webapp-sprint4-pipeline` using `Jenkinsfile.sprint4` from the repo.

Quick seed steps (Job DSL plugin):
1. Install the **Job DSL** plugin in Jenkins.
2. Create a new Freestyle job (e.g. `seed-job`).
3. Add a build step: **Process Job DSLs** → choose **Use the provided DSL script** and paste the contents of `ci/jenkins/sprint4_job.groovy` (or point the seed job at this repository).
4. Run `seed-job` — it will create `webapp-sprint4-pipeline`.

Alternative: use the Jenkins Script Console or CI bootstrap tooling to run the DSL script.

Credentials and prerequisites:
- Replace `github-credentials` inside the DSL with your SCM credential id if required.
- Create Jenkins credentials for AWS (access key / secret) and assign the ID used by your `Jenkinsfile.sprint4` (e.g., `aws-creds`).
- Ensure the Jenkins agent used by the pipeline has `docker`, `aws` CLI v2, and `kubectl` available and has network access to ECR/EKS.

Triggering the job:
Use the Jenkins UI or:

```
curl -X POST JENKINS_URL/job/webapp-sprint4-pipeline/build --user <user:api_token>
```

Notes: `Jenkinsfile.sprint4` is already in the repository root; the job uses that file. If you want me to attempt creating the job directly on your Jenkins server, grant access and credentials and I can run the seed step remotely.
