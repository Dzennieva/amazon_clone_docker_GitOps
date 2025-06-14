pipeline {
    agent any

    options {
        timeout(time: 10, unit: 'MINUTES') 
    }
    
    environment {
        DOCKERHUB_CREDS = credentials('docker_cred')
        IMAGE_URI= 'dzennieva/amazon'
    }
    stages {
        stage('SCM Checkout') {
            steps{
                echo "pass"
                // git branch: 'main', url: 'https://github.com/Dzennieva/amazon_clone_docker_img.git'
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
                trivy image $IMAGE_URI:$BUILD_NUMBER
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
        stage('Trigger Manifest') {
            environment {
                GITHUB_REPO = 'argocd_amazon_manifests'
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'git-cred', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                    git clone https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${GITHUB_USR_NAME}/${GITHUB_REPO}.git
                    cd ${GITHUB_REPO}
                    git config user.email "jenniferajibo.com"
                    git config user.name "Jennifer Ajibo"
                    BUILD_NUMBER=${BUILD_NUMBER}
                    sed -i "s/replaceImageTag/$BUILD_NUMBER/g" deployment.yaml
                    cat deployment.yaml 
                    git add deployment.yaml
                    git commit -m "Update image tag to $BUILD_NUMBER"
                    git push origin main
                    '''
}
            }
        }
    }
}