pipeline {
    agent {
        kubernetes {
            label 'java-pipeline'
            yaml """
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: maven
                image: maven:3.8.1-jdk-11
                command:
                - cat
                tty: true
                volumeMounts:
                - name: maven-cache
                  mountPath: /root/.m2
                - name: shared-workspace
                  mountPath: /workspace  # Mounting shared path in Maven container
              - name: docker
                image: docker:20.10.8
                command:
                - cat
                tty: true
                volumeMounts:
                - name: kubectl
                  mountPath: /usr/local/bin/kubectl
                - name: shared-workspace
                  mountPath: /workspace  # Mounting shared path in Docker container
                - name: docker-sock
                  mountPath: /var/run/docker.sock
              volumes:
              - name: kubectl
                hostpath:
                  path: /usr/local/bin/kubectl
              - name: shared-workspace
                emptyDir: {}  # An empty directory for sharing data between containers
              - name: maven-cache
                emptyDir: {}
              - name: docker-sock
                hostPath:
                  path: /var/run/docker.sock
            """
        }
    }
    
    environment {
        DOCKER_CREDENTIALS_ID = 'tushar3569-docker'  // DockerHub or JFrog credentials
        SONARQUBE_CREDENTIALS_ID = 'sonarqube-credentials' // SonarQube credentials
        ARTIFACTORY_URL = 'https://<your-artifactory-url>' // JFrog Artifactory URL
        AWS_CREDENTIALS = 'aws_keys'
        DOCKER_IMAGE = "tushar3569/sample-java-app:latest"
    }

    stages {
        stage('Checkout Code') {
            steps {
                container('maven') {
                    git credentialsId: 'tsingh.devops-github', branch: 'main', url: 'https://github.com/tsingh-PIP/sample-java-app.git'
                }
            }
        }

        stage('Maven Build') {
            steps {
                container('maven') {
                    sh 'mvn clean install'
                }
            }
        }

        stage('Run Unit Tests') {
            steps {
                container('maven') {
                    sh 'mvn test'
                    junit '**/target/surefire-reports/*.xml'
                    publishHTML([reportDir: 'target/site', reportFiles: 'index.html', reportName: 'HTML Report',keepAll: 'true',alwaysLinkToLastBuild: 'true', allowMissing: 'false'])
                }
            }
        }

        stage('Code Coverage') {
            steps {
                container('maven') {
                    sh 'mvn jacoco:report'
                    jacoco(execPattern: '**/target/*.exec', classPattern: '**/target/classes', sourcePattern: '**/src/main/java', exclusionPattern: '**/src/test*')
                }
            }
        }

        stage('Static Code Analysis') {
            steps {
                container('maven') {
                    withSonarQubeEnv('sonarqube') {
                        sh """
                        mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=sample-java-app \
                        -Dsonar.projectName='sample-java-app' \
                        -Dsonar.host.url=http://34.214.75.206:9000 \
                        -Dsonar.token=sqp_44c0f224984463f010181bfb163beda7f118e501
                        """
                    }
                }
            }
        }

        stage('Artifacts Upload'){
          steps{
            withAWS(credentials:'aws_keys', region:'us-west-2') {
            s3Upload(
              file: "target/spring-boot-2-hello-world-1.0.2-SNAPSHOT.jar",
              bucket: 'td-sample-java-app',
              path: ''
              )
            }
          }
        }

        stage('Docker Build & Push') {
            steps {
                container('docker') {
                    script {
                        withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
                            def image = docker.build("tushar3569/sample-java-app:latest")
                            image.push("latest")
                            sh 'docker logout'
                        }
                    }
                }
            }
        }

        stage('Deploy to Cloud') {
            steps {
                container('docker'){
                    sh """
                        kubectl get pods -n devops-tools
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Build and Deployment succeeded!'
        }
        failure {
            echo 'Build or Deployment failed.'
        }
    }
}
