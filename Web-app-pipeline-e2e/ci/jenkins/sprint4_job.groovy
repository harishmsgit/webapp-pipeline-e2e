// Job DSL to create the Sprint 4 pipeline job
pipelineJob('webapp-sprint4-pipeline') {
  description('Multi-stage pipeline for Sprint 4: build, test, push to ECR, deploy to EKS')

  definition {
    cpsScm {
      // Disable lightweight checkout to force a full checkout (avoids some revision lookup issues)
      lightweight(false)
      scm {
        git {
          remote {
            url('https://github.com/harishmsgit/webapp-pipeline-e2e.git')
            // Replace with your SCM credential ID if required
            credentials('harish-git-PAT')
          }
          // Use explicit refs/heads to avoid ambiguous branch resolution
          branches('refs/heads/feature/sprint4-EKS-ECR-Multi-Stage')
          // The repository root contains a top-level folder `Web-app-pipeline-e2e` in CI clones,
          // ensure the script path matches where the Jenkinsfile is located in the repo.
          scriptPath('Web-app-pipeline-e2e/Jenkinsfile.sprint4')
          extensions {
            // Check out the branch as a local branch to ensure a ref is available
            localBranch('feature/sprint4-EKS-ECR-Multi-Stage')
          }
        }
      }
    }
  }

  logRotator {
    numToKeep(10)
  }

  disabled(false)
}
