// Job DSL to create the Sprint 4 pipeline job
pipelineJob('webapp-sprint4-pipeline') {
  description('Multi-stage pipeline for Sprint 4: build, test, push to ECR, deploy to EKS')

  definition {
    cpsScm {
      scm {
        git {
          remote {
            url('https://github.com/harishmsgit/webapp-pipeline-e2e.git')
            // Replace with your SCM credential ID if required
            credentials('github-credentials')
          }
          // Checkout the feature branch created for Sprint 4
          branches('*/feature/sprint4-EKS-ECR-Multi-Stage')
          scriptPath('Jenkinsfile.sprint4')
          extensions {}
        }
      }
    }
  }

  logRotator {
    numToKeep(10)
  }

  disabled(false)
}
