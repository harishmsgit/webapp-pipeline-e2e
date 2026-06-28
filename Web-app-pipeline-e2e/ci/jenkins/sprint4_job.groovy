// Job DSL to create the Sprint 4 pipeline job
pipelineJob('webapp-sprint4-pipeline') {
  description('Multi-stage pipeline for Sprint 4: build, test, push to ECR, deploy to EKS')

  definition {
    cpsScm {
      // Disable lightweight checkout to force a full checkout (avoids some revision lookup issues)
      lightweight(false)
      scm {
          git {
            // Prefer seed-job parameter `GIT_CREDENTIALS_ID`, then env var, then fallback
            def gitCredentialsId = (this.binding?.hasVariable('GIT_CREDENTIALS_ID') ? this.binding.getVariable('GIT_CREDENTIALS_ID') : System.getenv('GIT_CREDENTIALS_ID')) ?: 'harish-git-PAT'
            remote {
              url('https://github.com/harishmsgit/webapp-pipeline-e2e.git')
              credentials(gitCredentialsId)
            }
          // Use explicit branch spec to select the correct feature branch
          branches('*/feature/sprint4-EKS-ECR-Multi-Stage')
          // The Jenkinsfile is stored in the nested checkout directory created by this repo.
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
