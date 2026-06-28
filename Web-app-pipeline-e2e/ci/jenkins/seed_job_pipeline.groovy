pipeline {
  agent any

  parameters {
    string(name: 'GIT_CREDENTIALS_ID', defaultValue: 'github-token', description: 'Jenkins credential id for Git access')
  }

  stages {
    stage('Create Seed Job') {
      steps {
        script {
          def xml = """<?xml version='1.1' encoding='UTF-8'?>
<project>
  <actions/>
  <description>Seed job to process Job DSL for Sprint4 pipelines</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>GIT_CREDENTIALS_ID</name>
          <description>Credential id in Jenkins to use for Git access (optional)</description>
          <defaultValue>${params.GIT_CREDENTIALS_ID}</defaultValue>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <scm class=\"hudson.scm.NullSCM\"/>
  <canRoam>true</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers/>
  <concurrentBuild>false</concurrentBuild>
  <builders>
    <javaposse.jobdsl.plugin.ExecuteDslScripts plugin=\"job-dsl@1.77\">
      <targets>ci/jenkins/sprint4_job.groovy
ci/jenkins/sprint4_multibranch.groovy</targets>
      <usingScriptText>false</usingScriptText>
      <ignoreExisting>false</ignoreExisting>
      <ignoreMissingFiles>false</ignoreMissingFiles>
      <failOnMissingPlugin>false</failOnMissingPlugin>
      <lookupStrategy>JENKINS_ROOT</lookupStrategy>
      <additionalClasspath/>
    </javaposse.jobdsl.plugin.ExecuteDslScripts>
  </builders>
  <publishers/>
  <buildWrappers/>
</project>"""

          writeFile file: 'seed-job-config.xml', text: xml
          echo 'Created seed job XML config.'
        }
      }
    }
  }
}
