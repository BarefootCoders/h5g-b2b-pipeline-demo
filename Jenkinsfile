/**
* Copyright 2019 Google LLC
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

pipeline {
  agent any
  options {
    // Prevent more than one of this pipeline from running at once
    disableConcurrentBuilds()
  }
  environment {
    PROJECT_GIT_URL = "ssh://git@10.55.10.200:7999/bbin/b2b-asset-pipeline-demo.git"
    GIT_CLONE_CREDENTIAL_NAME = 'b2b-pipeline-deployer-bitbucket-deploy-key'
    GOOGLE_APPLICATION_CREDENTIAL_NAME = "SERVICE-ACCOUNT-asset-deployer.iam.gserviceaccount.com"
    CLI_DOCKER_IMAGE = "gcr.io/h5g-demo-img/h5g-b2b-pipeline-deployment-manager:cli"
  }

  stages {
    stage('Prepare') {
      when {
        expression {
          return env.BRANCH_NAME == "master"
        }
      }
      steps {
        dir ("${env.WORKSPACE}"){
          checkout scm: [
            $class: 'GitSCM', userRemoteConfigs: [
                     [
                     url: env.PROJECT_GIT_URL,
                     credentialsId: env.GIT_CLONE_CREDENTIAL_NAME,
                     changelog: false,
                     ]
            ],
            branches: [
                     [
                     name: env.BRANCH_NAME
                     ]
            ],
            poll: false
          ]
        }
      }
    }
    stage('Migrate and Plan') {
      when {
        expression {
          return env.BRANCH_NAME == "master"
        }
      }
      steps {
        dir ("${env.WORKSPACE}"){
          withCredentials([file(credentialsId: env.GOOGLE_APPLICATION_CREDENTIAL_NAME, variable: "GOOGLE_APPLICATION_CREDENTIAL_FILE")]) {
            sshagent (credentials: [env.GIT_CLONE_CREDENTIAL_NAME]) {
              sh 'echo "Authenticating as user: $(cat $GOOGLE_APPLICATION_CREDENTIAL_FILE | grep client_email)"'
              sh "docker pull ${env.CLI_DOCKER_IMAGE}"
              sh "ssh-add -l"
              sh "docker run -v \"\$(pwd)\"/migrations:/migrations -v \"\$(pwd)\"/pipeline:/pipeline -v \"\$(pwd)\"/hcl:/hcl ${env.CLI_DOCKER_IMAGE} --migration-dir=/migrations --pipeline-file=/pipeline/b2b-asset-pipeline.yaml --pipeline-output-file=/pipeline/b2b-asset-pipeline.yaml --hcl-output-dir=/hcl"
              sh "cd hcl && GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIAL_FILE terraform init && GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIAL_FILE terraform plan -out ../planfile"
            }
          }
        }

        archiveArtifacts 'planfile'
        stash includes: 'planfile', name: 'planfile'
        stash includes: 'pipeline/b2b-asset-pipeline.yaml', name: 'pipeline'
        stash includes: 'hcl/main.tf', name: 'hcl'
      }
    }
    stage('Apply') {
      when {
        expression {
          return env.BRANCH_NAME == "master"
        }
      }
      steps {
        dir ("${env.WORKSPACE}") {
          unstash name: 'hcl'
          unstash name: 'planfile'
          /* input 'Do you want to apply this plan?' */
          withCredentials([file(credentialsId: env.GOOGLE_APPLICATION_CREDENTIAL_NAME, variable: "GOOGLE_APPLICATION_CREDENTIAL_FILE")]) {
            sh "pip install google-cloud-storage requests-toolbelt requests"
            sh "cd hcl && GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIAL_FILE terraform init && GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIAL_FILE terraform apply ../planfile"
          }
        }
      }
    }
    stage('Commit and push') {
      when {
        expression {
          return env.BRANCH_NAME == "master"
        }
      }
      steps {
        dir ("${env.WORKSPACE}") {
          sh "git checkout master"
          unstash name: 'pipeline'
          unstash name: 'hcl'
          sshagent (credentials: [env.GIT_CLONE_CREDENTIAL_NAME]) {
            sh "git add pipeline/ hcl/ && git commit -m \"Released compiled pipeline at ${currentBuild.startTimeInMillis} by Jenkins\" && git push origin master"
          }
        }
      }
    }
  }

  post {
    always {
      echo "Clearing workspace"
      deleteDir()
    }
  }
}
