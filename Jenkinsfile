pipeline {
    agent any

    environment {
        // ---- Change these to match your setup ----
        GIT_REPO        = 'https://github.com/Ragul-Gandhi/Trendify-app.git'
        GIT_BRANCH      = 'main'
        DOCKERHUB_USER  = 'ragulgandhi'
        IMAGE_NAME      = "${DOCKERHUB_USER}/trend-app"
        IMAGE_TAG       = "${BUILD_NUMBER}"
        AWS_REGION      = 'ap-south-1'
        AWS_DEFAULT_REGION = 'ap-south-1'
        CLUSTER_NAME    = 'ragul'
        K8S_NAMESPACE   = 'default'
        K8S_MANIFEST    = 'K8s/Trend.yml'   // Deployment + Service file in the repo
        DEPLOYMENT_NAME = 'trend-app-deploy'            // metadata.name in the Deployment
        CONTAINER_NAME  = 'project-2-app'            // container name inside the Deployment
        // Jenkins credential ID (AWS access uses the EC2 instance role EC2_EKS)
        DOCKERHUB_CREDS = 'dockerhub-creds'       // Username with password
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: "${GIT_BRANCH}", url: "${GIT_REPO}"
            }
        }

        stage('Tool Check') {
            steps {
                sh '''
                    docker --version
                    kubectl version --client
                    aws --version
                    aws sts get-caller-identity
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDS}",
                                                  usernameVariable: 'DH_USER',
                                                  passwordVariable: 'DH_PASS')]) {
                    sh '''
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Configure kubectl for EKS') {
            steps {
                sh '''
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
                    kubectl get nodes
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    # Apply Deployment + Service (creates them on first run)
                    kubectl apply -f ${K8S_MANIFEST} -n ${K8S_NAMESPACE}

                    # Roll out the image built in this run
                    kubectl set image deployment/${DEPLOYMENT_NAME} \
                        ${CONTAINER_NAME}=${IMAGE_NAME}:${IMAGE_TAG} \
                        -n ${K8S_NAMESPACE}
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    kubectl rollout status deployment/${DEPLOYMENT_NAME} \
                        -n ${K8S_NAMESPACE} --timeout=180s
                    kubectl get pods -n ${K8S_NAMESPACE} -o wide
                    kubectl get svc  -n ${K8S_NAMESPACE}
                '''
            }
        }
    }

    post {
        success {
            echo "Trendstore ${IMAGE_TAG} deployed to EKS cluster ${CLUSTER_NAME}."
        }
        failure {
            echo 'Pipeline failed. Rolling back the deployment.'
            sh '''
                kubectl rollout undo deployment/${DEPLOYMENT_NAME} \
                    -n ${K8S_NAMESPACE} || true
            '''
        }
        always {
            sh '''
                docker logout || true
                docker image prune -f || true
            '''
        }
    }
}

