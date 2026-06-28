// Multibranch Pipeline Job DSL for Sprint 4
multibranchPipelineJob('webapp-sprint4-multibranch') {
  // Prefer seed-job parameter `GIT_CREDENTIALS_ID`, then env var, then fallback
  def gitCredentialsId = (this.binding?.hasVariable('GIT_CREDENTIALS_ID') ? this.binding.getVariable('GIT_CREDENTIALS_ID') : System.getenv('GIT_CREDENTIALS_ID')) ?: 'harish-git-PAT'
  description('Multibranch pipeline for Sprint 4: discovers branches and runs Jenkinsfile.sprint4')

  branchSources {
    branchSource {
      source {
          git {
          id('webapp-pipeline-e2e')
          remote('https://github.com/harishmsgit/webapp-pipeline-e2e.git')
          // Use environment-overridable credential id
          credentials(gitCredentialsId)
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

  // Filter branches to only build selected branch names (main and develop)
  configure { project ->
    def sources = project / 'branchSources' / 'data' / 'jenkins.branch.BranchSource'
    sources.each { bs ->
      def src = bs / 'source'
      def traits = src / 'traits'
      traits << 'org.jenkinsci.plugins.github_branch_source.FilterByNameTrait' {
        includes('main develop')
        excludes('')
      }
    }
  }

  // Do not enable automatic triggers by default; seed job will create the multibranch job.
  disabled(false)
}
