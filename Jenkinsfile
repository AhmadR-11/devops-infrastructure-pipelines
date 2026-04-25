pipeline {
    // This enforces that the pipeline runs ONLY on your new private subnet agent!
    agent {
        label 'linux-agent'
    }

    stages {
        stage('Checkout') {
            steps {
                // Jenkins automatically checks out the GitHub repository branch
                checkout scm
                echo '✅ Source code checked out successfully.'
            }
        }

        stage('Build') {
            // We use the Docker Pipeline plugin to spin up a Node.js container instantly
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                dir('app') {
                    sh 'npm install'
                    echo '✅ Application built (dependencies installed).'
                }
            }
        }

        stage('Test') {
            failFast true
            parallel {
                stage('Unit Tests') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
                        }
                    }
                    steps {
                        dir('app') {
                            sh 'npm run test:unit'
                        }
                    }
                    post {
                        always {
                            dir('app') {
                                junit 'unit-report.xml'
                            }
                        }
                    }
                }
                stage('Integration Tests') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
                        }
                    }
                    steps {
                        dir('app') {
                            sh 'npm run test:integration'
                        }
                    }
                    post {
                        always {
                            dir('app') {
                                junit 'integration-report.xml'
                            }
                        }
                    }
                }
            }
        }

        stage('Package') {
            steps {
                dir('app') {
                    // Uses the Dockerfile to package the entire app into a Docker Image
                    sh 'docker build -t sample-express-app:latest .'
                    echo '✅ Application packaged into a Docker container.'
                }
            }
        }

        stage('Deploy') {
            steps {
                echo '🚀 Deploying application to the agent server...'
                // This cleans up any old versions before deploying the new one
                sh 'docker stop sample-app || true'
                sh 'docker rm sample-app || true'
                // This officially runs the app on your private agent server!
                sh 'docker run -d -p 3000:3000 --name sample-app sample-express-app:latest'
                echo '✅ Application successfully deployed and running on port 3000.'
            }
        }
    }
}
