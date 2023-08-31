#!/usr/bin/env groovy

pipeline {
    agent any
    tools {
        maven 'my-maven'
    }    
    stages {
        stage('increment version') {
            steps {
                script {
                    echo "incrementing app version....."
                    sh 'mvn build-helper:parse-version versions:set -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} versions:commit'
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                    def version = matcher[0][1]
                    env.IMAGE_NAME = "$version-$BUILD_NUMBER"
                }
            }
        }
        stage('build app') {
            steps {
                script {
                    echo "Building the application....."
                    sh 'mvn clean package'
                }
            }
        }
        stage('build image') {
            steps {
                script {
                    echo "Building the docker image..."
                    withCredentials ([usernamePassword(credentialsId: 'sk-dockerhub-cred', passwordVariable:'PASS', usernameVariable: 'USER')]) {
                       sh "docker build -t vsrujan/demo-app:${IMAGE_NAME} ."
                       sh "echo $PASS | docker login -u $USER --password-stdin"
                       sh "docker push vsrujan/demo-app:${IMAGE_NAME}" }
                }
            }
        }

        stage('provision server') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_secret_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                TF_VAR_env_prefix = 'test'
            }
            steps {
                script {
                    dir ('terraform') {
                        echo "Provisioning the server..."
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                        EC2_PUBLIC_IP = sh (
                            script: "terraform output ec2_public_ip"
                            returnStdout: true
                        ).trim()
                    }
                }
            }
        }

        stage('deploy') {
            steps {
                script {
                    echo "Waiting for server to be ready..."
                    sleep(time: 90, unit: 'SECONDS')

                    echo "EC2_PUBLIC_IP: ${EC2_PUBLIC_IP}"

                    env.IMAGE = "vsrujan/demo-app:${IMAGE_NAME}"
                    echo "Deploying docker image..."
                    def shellCmd = "bash ./server-cmds.sh ${IMAGE}"
                    def ec2Instance = "ec2-user@${EC2_PUBLIC_IP}"

                    sshagent(['server-server-key']) {
                        sh "scp -o StrictHostKeyChecking=no server-cmds.sh ${ec2Instance}:/home/ec2-user"
                        sh "scp -o StrictHostKeyChecking=no docker-compose.yaml ${ec2Instance}:/home/ec2-user"
                        sh "ssh -o StrictHostKeyChecking=no ${ec2Instance} ${shellCmd}"
                    }
                }
            }
        }
        stage('commit version update') {
            steps {
                script {
                    withCredentials ([usernamePassword(credentialsId: 'jenkins-github', passwordVariable:'PASS', usernameVariable: 'USER')]) {

                        sh 'git status'
                        sh 'git branch'
                        sh 'git config --list'
                        sh "git remote set-url origin https://${USER}:${PASS}@github.com/srujanvk/java-maven-app.git"
                        sh 'git add .'
                        sh 'git commit -m "ci: version bump"'
                        sh 'git push origin HEAD:jenkins-jobs'
                     }
                 }
            }
        }
    }
}
