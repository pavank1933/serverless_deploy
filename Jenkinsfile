@Library('jenkins-shared-utils') _
pipeline {
  options {
    disableConcurrentBuilds()
  }
  agent {
    docker {
      image "lambci/lambda:build-nodejs12.x"
    }
  }
  stages {
    stage('Build and Deploy') {
    steps {
        script {
            switch(env.GIT_BRANCH) {
                case "billing_staging_env":
                  props = readProperties file: 'properties/deploy-staging.properties'
                  break
                case "qa":
                  props = readProperties file: 'properties/deploy-qa.properties'
                  break
                case "prod":
                  props = readProperties file: 'properties/deploy-prod.properties'
                  break
                default:
                  props = "NONE"
                  echo("This is feature branch and props is...: ${props}")
              }
		        if(props == "NONE"){
		        currentBuild.result = 'SUCCESS'
		        return
		        }

            echo "PROPS DATA: ${props}"
            def AWS_INFRA_DEPLOY = props.AWS_INFRA_DEPLOY
            def APP_DEPLOY = props.APP_DEPLOY

            def tf_action = props.tf_action
            def role_arn = props.role_arn
	          def ec2_keypair_name = props.ec2_keypair_name
            def ami_nat_instance = props.ami_nat_instance
            def environment = props.environment
            def tag_aws_env = props.tag_aws_env
            def lambda_handler_map = props.lambda_handler_map
            def len = null;
            def handlers = null;
            handler = props.handler
            lambda = props.lambda
            aws_region = props.aws_region
            aws_account_id = props.aws_account_id
            ecr_repo = props.ecr_repo
            docker_image_name = props.docker_image_name
            artifact_version = props.artifact_version
            branch_name = env.GIT_BRANCH
            
            def (app_name, latest) = docker_image_name.tokenize( '-' )
            final_docker_image = app_name + '-' + artifact_version + '-' + latest

            echo "Final docker image version.... ${final_docker_image}"


            withCredentials([
                [credentialsId: "${environment}", $class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']
            ])
            {
            if (AWS_INFRA_DEPLOY == 'true' && tf_action == 'apply' ) {
               sh "rm -rf terraform_1.* && yum install wget -y && wget -q https://releases.hashicorp.com/terraform/1.0.3/terraform_1.0.3_linux_amd64.zip && unzip terraform_1.0.3_linux_amd64.zip && mv terraform /usr/local/bin/"
               env.TF_VAR_aws_region=aws_region
			         env.TF_VAR_aws_account_id=aws_account_id
			         env.TF_VAR_ecr_repo=ecr_repo
               env.TF_VAR_role_arn=role_arn
			         env.TF_VAR_ec2_keypair_name=ec2_keypair_name
               env.TF_VAR_ami_nat_instance=ami_nat_instance
               env.TF_VAR_tag_aws_env=tag_aws_env
               env.TF_VAR_artifact_version=artifact_version
               /*sh '''#!/bin/bash
                 #Stops scripts if any below command fails
                 #set -e
                 #export TF_VAR_aws_region=''' +aws_region+'''
                 #export TF_VAR_aws_account_id=''' +aws_account_id+'''
                 #export TF_VAR_ecr_repo=''' +ecr_repo+'''
                 #export TF_VAR_role_arn=''' +role_arn+'''
                 #export TF_VAR_ec2_keypair_name=''' +ec2_keypair_name+'''
                 #export TF_VAR_ami_nat_instance=''' +ami_nat_instance+'''
                 #export TF_VAR_tag_aws_env=''' +tag_aws_env+'''
                 #export TF_VAR_artifact_version=''' +artifact_version+'''
                 #if aws s3api head-bucket --bucket "adserverx-tfstate-qa" 2>/dev/null; then 
                 #   echo "Bucket TF_STATE exists...skipping terraform backend stuff..."
                 #else
                 #   echo "Terraform backend bucket not exists..."
                 #   cd tfscripts/tfbackend
                 #   terraform init 
                 #   terraform plan 
                 #   terraform apply -refresh-only -input=false -auto-approve
                 #fi
               '''*/
               sh '''#!/bin/bash
                    #Stops scripts if any below command fails
                    set -e
                    #export TF_VAR_aws_region=''' +aws_region+'''
                    #export TF_VAR_aws_account_id=''' +aws_account_id+'''
                    #export TF_VAR_ecr_repo=''' +ecr_repo+'''
                    #export TF_VAR_role_arn=''' +role_arn+'''
                    #export TF_VAR_ec2_keypair_name=''' +ec2_keypair_name+'''
                    #export TF_VAR_ami_nat_instance=''' +ami_nat_instance+'''
                    #export TF_VAR_tag_aws_env=''' +tag_aws_env+'''
                    #export TF_VAR_artifact_version=''' +artifact_version+'''
                    cd tfscripts/billing
                    #terraform init -backend-config="bucket=adserverx-tfstate-qa" -backend-config="key=states/terraform.tfstate" -backend-config="region=us-east-1" -backend=true -force-copy -get=true -input=false
                    #terraform state list
                    #terraform plan 
                    #TF_LOG=DEBUG  terraform plan 
                    #terraform apply -input=false -auto-approve
                    #terraform apply -refresh-only -input=false -auto-approve
                    #terraform apply -input=false -auto-approve -refresh=false
                    terraform init
                    terraform plan
                    terraform apply -input=false -auto-approve
                  '''
              }
              else if(AWS_INFRA_DEPLOY == 'true' && tf_action == 'destroy')
              {
                sh "rm -rf terraform_1.* && yum install wget -y && wget -q https://releases.hashicorp.com/terraform/1.0.3/terraform_1.0.3_linux_amd64.zip && unzip terraform_1.0.3_linux_amd64.zip && mv terraform /usr/local/bin/"
               //  env.TF_VAR_aws_region=aws_region
			         //  env.TF_VAR_aws_account_id=aws_account_id
			         //  env.TF_VAR_ecr_repo=ecr_repo
               //  env.TF_VAR_role_arn=role_arn
			         //  env.TF_VAR_ec2_keypair_name=ec2_keypair_name
               //  env.TF_VAR_ami_nat_instance=ami_nat_instance
               //  env.TF_VAR_tag_aws_env=tag_aws_env
               //  env.TF_VAR_artifact_version=artifact_version 
                sh '''#!/bin/bash
                     set -e
                     export TF_VAR_aws_region=''' +aws_region+'''
                     export TF_VAR_aws_account_id=''' +aws_account_id+'''
                     export TF_VAR_ecr_repo=''' +ecr_repo+'''
                     export TF_VAR_role_arn=''' +role_arn+'''
                     export TF_VAR_ec2_keypair_name=''' +ec2_keypair_name+'''
                     export TF_VAR_ami_nat_instance=''' +ami_nat_instance+'''
                     export TF_VAR_tag_aws_env=''' +tag_aws_env+'''
                     export TF_VAR_artifact_version=''' +artifact_version+'''
                     cd tfscripts
                     echo "Destroying infra....."
                     ls -la
                     #terraform init -reconfigure
                     #terraform init -backend-config="bucket=adserverx-tfstate-qa" -backend-config="key=states/terraform.tfstate" -backend-config="region=us-east-1" -backend=true -force-copy -get=true -input=false
                     #terraform destroy -input=false -auto-approve
                   '''
              }
              else{
                echo "No infra changes using Terraform...Proceeding with deploy..."
              }

              if (APP_DEPLOY == 'true' && handler?.trim()) {

                  sh '''#!/bin/bash
                         #Stops scripts if any below command fails
                         set -e
                         rm -rf terraform_1.*
                         #cp -rpf properties/deploy-''' +branch_name+'''.properties properties/app.properties
                         cp -rpf properties/deploy-staging.properties properties/app.properties
                         echo "Displaying app.properties file contents..."
                         cat properties/app.properties
                         echo "Building npm tests..."
                         npm install jest-html-reporter --save-dev
                         npm test
                     '''
                  
                  publishHTML target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: '/var/jenkins_home/workspace/c_adserver-x_${branch_name}/',
                        //reportDir: '/var/jenkins_home/workspace/c_adserver-x_billing_staging_env/',
                        reportFiles: 'test-report.html',
                        reportName: 'BuildReport'
                    ]

                  // handlers = handler.split(',')
                  // len = handlers.size()                        
                  // //Convert lambda_handler to dict
                  // lambda_handler_map = lambda_handler_map.replaceAll('\\[|\\]','')
                  // def lambdaMap = [:]
                  // lambda_handler_map.tokenize(',').each {
                  // kvTuple = it.tokenize(':')
                  // lambdaMap[kvTuple[0]] = kvTuple[1]
                  // }
                  // sh '''#!/bin/bash
                  //        #Stops scripts if any below command fails
                  //        set -e
                  //        rm -rf terraform_1.*
                  //        #cp -rpf properties/deploy-''' +branch_name+'''.properties properties/app.properties
                  //        cp -rpf properties/deploy-staging.properties properties/app.properties
                  //        echo "Displaying app.properties file contents..."
                  //        cat properties/app.properties
                  //        echo "Building npm tests..."
                  //        npm install jest-html-reporter --save-dev
                  //        npm test
                  //    '''
                  
                  // publishHTML target: [
                  //       allowMissing: false,
                  //       alwaysLinkToLastBuild: false,
                  //       keepAll: true,
                  //       reportDir: '.',
                  //       reportFiles: 'Test-report.html',
                  //       reportName: 'npm build Report'
                  //   ]

                /*for (i = 0; i < len; i++)
                  {
                    def lambda_name = lambdaMap.findAll { key, value -> key.contains(handlers[i]) }.values().sum()
                    if (lambda_name)
                    {
                      echo "Lambda name is.....: $lambda_name"
                    }
                    else
                    {
                      echo "Wrong lambda name and is null....exiting....: $lambda_name"
                      exit 1 
                    }
                    def handler_name = handlers[i]                
                    sh "aws ecr get-login-password --region $aws_region | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com"
                    sh "echo 'Updating Dockerfile with Handler: $handler_name'"
                    sh '''sed -i '$ d' Dockerfile'''
                    sh(returnStdout: true, script: '''#!/bin/bash
                    if [[ ''' +handler_name+''' = "writeEventToSQS" ]] ; then
                        echo 'CMD [\"dist/src/writeEventToSQS.''' +handler_name+'''\"]' >> Dockerfile;
                    elif [[ ''' +handler_name+''' = "billingBeaconEventToSQS" ]] ; then
                        echo 'CMD [\"dist/src/writeEventToSQS.''' +handler_name+'''\"]' >> Dockerfile;
                    else
                        echo 'CMD [\"dist/src/handler.''' +handler_name+'''\"]' >> Dockerfile;
                    fi
                    '''.stripIndent())
                    sh "echo 'Displaying Updated Dockerfile content with LAMBDA_FUNC_NAME: $handler_name'"
                    sh '''#!/bin/bash
                       #Stops scripts if any below command fails
                       set -e
                       cat Dockerfile
                       docker build -t ''' +ecr_repo+''':''' +final_docker_image+''' .
                       docker images
                       docker tag  ''' +ecr_repo+''':''' +final_docker_image+''' ''' +aws_account_id+'''.dkr.ecr.us-east-1.amazonaws.com/''' +ecr_repo+''':''' +final_docker_image+'''
                       docker push ''' +aws_account_id+'''.dkr.ecr.''' +aws_region+'''.amazonaws.com/''' +ecr_repo+''':''' +final_docker_image+'''
                       aws lambda update-function-code --region ''' +aws_region+''' --function-name ''' +lambda_name+''' --image-uri ''' +aws_account_id+'''.dkr.ecr.''' +aws_region+'''.amazonaws.com/''' +ecr_repo+''':''' +final_docker_image+'''
                       docker image prune -af
                    ''' 
                }*/
              }
              else{
              echo "Zero deployments...."
            }
            }
        }
      }
    }
  }
}
