@Library('jenkins-shared-library') _

pipeline {
    // This enforces that the pipeline runs ONLY on your new private subnet agent!
    agent {
        label 'linux-agent'
    }

    environment {
        // Securely injects the Slack Webhook without exposing the plaintext URL
        SLACK_WEBHOOK_URL = credentials('slack-webhook')
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

        stage('Static Analysis & Quality Gate') {
            agent {
                docker {
                    image 'node:18' // Must use standard Node (not alpine) because SonarQube requires Java glibc
                    reuseNode true
                }
            }
            steps {
                dir('app') {
                    echo '🔍 Running SonarQube Code Quality Analysis...'
                    runSonarScan(projectKey: 'sample-express-app')
                }
                
                // This forces Jenkins to wait for SonarQube to calculate the score!
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Container Build') {
            steps {
                script {
                    // Generate a 7-character short Git commit SHA
                    env.SHORT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    // Extract the branch name (removes the "origin/" prefix provided by Jenkins)
                    env.CLEAN_BRANCH = env.GIT_BRANCH ? env.GIT_BRANCH.split('/').last() : 'main'
                }
                dir('app') {
                    // Build and tag the image twice: once with the SHA, once with the branch name
                    sh 'docker build -t sample-express-app:$SHORT_SHA -t sample-express-app:$CLEAN_BRANCH .'
                    echo "✅ Image tagged as sample-express-app:${env.SHORT_SHA} and sample-express-app:${env.CLEAN_BRANCH}"
                }
            }
        }

        stage('Deploy') {
            steps {
                echo '🚀 Deploying application to the agent server...'
                // This cleans up any old versions before deploying the new one
                sh 'docker stop sample-app || true'
                sh 'docker rm sample-app || true'
                // This officially runs the app using our newly generated Short SHA tag!
                sh 'docker run -d -p 3000:3000 --name sample-app sample-express-app:$SHORT_SHA'
                echo '✅ Application successfully deployed and running on port 3000.'
            }
        }
    }

    post {
        always {
            echo '📦 Archiving build artifacts...'
            // Archives the package.json and test XML reports so they can be downloaded from the Jenkins UI
            archiveArtifacts artifacts: 'app/package.json, **/*.xml', allowEmptyArchive: true
        }
        success {
            echo '✅ Pipeline Succeeded! Sending notification...'
            // We replaced the ugly curl command with our beautiful new Shared Library step!
            notifySlack(message: "✅ SUCCESS: Jenkins Pipeline ${env.JOB_NAME} Build #${env.BUILD_NUMBER} passed! View it here: ${env.BUILD_URL}")
        }
        failure {
            echo '❌ Pipeline Failed! Sending notification...'
            // We replaced the ugly curl command with our beautiful new Shared Library step!
            notifySlack(message: "❌ FAILURE: A stage failed in Jenkins Pipeline ${env.JOB_NAME} Build #${env.BUILD_NUMBER}. Check logs here: ${env.BUILD_URL}")
        }
    }
}
