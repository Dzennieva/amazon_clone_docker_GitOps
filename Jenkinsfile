pipeline {
    agent any

    // options {
    //     timeout(time: 10, unit: 'MINUTES') 
    // }
    
    environment {
        DOCKERHUB_CREDS = credentials('docker_cred')
        IMAGE_URI= 'dzennieva/amazon'
    }
    stages {
        stage('SCM Checkout') {
            steps {
            echo "pass"
            // checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/Dzennieva/amazon_clone_docker_img.git']])
            }
        }
        stage('Sonarqube Analysis') {
            environment {
                SCANNER_HOME = tool 'sonar-scanner'
            }
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                    ${SCANNER_HOME}/bin/sonar-scanner 
                    '''
                }
            }
        }
        stage('Build Docker Image') {
            steps{
                sh '''
                docker build -t $IMAGE_URI:$BUILD_NUMBER .
                docker images $IMAGE_URI
                '''
            }
        }
       stage('Trivy Scan Image') {
           steps {
               sh '''
               trivy image --scanners vuln $IMAGE_URI:$BUILD_NUMBER
               '''
           }
        
       }
        stage('Push Image to Docker Hub') {
            steps {
                sh '''
                echo "$DOCKERHUB_CREDS_PSW" | docker login -u "$DOCKERHUB_CREDS_USR" --password-stdin
                docker push $IMAGE_URI:$BUILD_NUMBER
                ''' 
            }
        }
        stage('Update Deployment File') {
            
            steps {
            
                withCredentials([usernamePassword(credentialsId: 'git_cred', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                    git config user.email "jenniferajibo@gmail.com"
                    git config user.name "Dzennieva"
                    
                    sed -i "s|image:.*|image: ${DOCKERHUB_CREDS_USR}/amazon:${BUILD_NUMBER}|g" argoCD/deployment.yml
                    cat argoCD/deployment.yml
                    
                    git add argoCD/deployment.yml
                    git commit -m "Update image tag to $BUILD_NUMBER"
                    git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${GIT_USERNAME}/amazon_clone_docker_GitOps.git HEAD:main
                    '''
                }
            }
        }
    }
    post {
        success {
            emailext(
            to: 'jenniferajibo@gmail.com',
            subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: "Good news! The build succeeded.\n${env.BUILD_URL}"
             )
        }
        failure {
            emailext(
            to: 'jenniferajibo@gmail.com',
            subject: "FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: "Something went wrong!\nCheck console output: ${env.BUILD_URL}"
            )
        }
    }
}
