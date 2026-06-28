// Multibranch Pipeline Job DSL for Sprint 4
multibranchPipelineJob('webapp-sprint4-multibranch') {
  description('Multibranch pipeline for Sprint 4: discovers branches and runs Jenkinsfile.sprint4')

  branchSources {
    branchSource {
      source {
        git {
          id('webapp-pipeline-e2e')
          remote('https://github.com/harishmsgit/webapp-pipeline-e2e.git')
          // Replace with your SCM credential id if required
          credentials('harish-git-PAT')
        }
      }
    }
  }

  factory {
    workflowBranchProjectFactory {
      // Use the repository-relative path to the pipeline script
      scriptPath('Web-app-pipeline-e2e/Jenkinsfile.sprint4')
    }
  }

  orphanedItemStrategy {
    discardOldItems {
      numToKeep(20)
    }
  }

  // Do not enable automatic triggers by default; seed job will create the multibranch job.
  disabled(false)
}
