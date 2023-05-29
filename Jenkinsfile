# jenkins pipeline to create infra on aws with code on git
# global credentials: AWS_ACCESS_KEY_ID=<your aws key>
# global credentials: AWS_SECRET_ACCESS_KEY=<your aws secret key>
# project = pipeline
# with parameter: type=choice | name=action | choices=apply destroy
# definition: pipeline script from scm
###
# also install terraform on jenkins server and configure its path 
# 

### Jenkinsfile need to be on git

pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }

    stages {
        stage('Cloning Git') {
            steps {
            checkout scm         

          }
        }
        
        stage ("terraform init") {
            steps {
                sh ('terraform init') 
            }
        }
        
        stage ("terraform Action") {
            steps {
                echo "Terraform action is --> ${action}"
                sh ('terraform ${action} --auto-approve') 
           }
        }
    }
}
