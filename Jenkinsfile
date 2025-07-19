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
            //    checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/Dzennieva/amazon_clone_docker_img.git']])
            }
        }
        stage('Sonar-scanner') {
            environment{
                SCANNER_HOME = tool 'sonar7.1'
            }
            steps {
                withSonarQubeEnv('ibt-sonar') {
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
                docker images --filter=reference=$IMAGE_URI
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
            environment {
                GITHUB_REPO = 'argocd_amazon_manifests'
            }
            steps {
                deleteDir()
                withCredentials([usernamePassword(credentialsId: 'git-cred', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh """
                    git config user.email "jenniferajibo@yahoo.com"
                    git config user.name "Jennifer Ajibo"
                    BUILD_NUMBER=$BUILD_NUMBER
                    sed -i 's|replaceImgTag|${BUILD_NUMBER}|g' deployment.yml
                    cat deployment.yml 
                    git add deployment.yml
                    git commit -m "Update image tag to $BUILD_NUMBER"
                    git push origin main
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed. Cleaning up Docker image..."
            sh "docker rmi dzennieva/amazon:${BUILD_NUMBER} || true"
        }
    }
}
