@Library('jenkins-shared-library') _

pipeline {
    // This enforces that the pipeline runs ONLY on your new private subnet agent!
    agent {
        label 'linux-agent'
    }

    environment {
        // Securely injects the Slack Webhook without exposing the plaintext URL
        SLACK_WEBHOOK_URL = credentials('slack-webhook')
        AWS_DEFAULT_REGION = 'us-east-1'
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

        stage('Security Scan') {
            steps {
                echo '🔍 Running Trivy Vulnerability Scan...'
                
                // 1. Run the scan to generate a report file (we mount /workspace to save the file)
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${env.WORKSPACE}/.trivyignore:/.trivyignore -v ${env.WORKSPACE}:/workspace aquasec/trivy image --format table --output /workspace/trivy-report.txt --severity HIGH,CRITICAL --ignore-unfixed sample-express-app:${env.SHORT_SHA}"
                
                // 2. Display the report in the console so you can see it
                sh "cat trivy-report.txt"
                
                // 3. Run the scan with exit-code 1 and the ignorefile to actually enforce the Quality Gate
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${env.WORKSPACE}/.trivyignore:/.trivyignore aquasec/trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed --ignorefile /.trivyignore sample-express-app:${env.SHORT_SHA}"
                
                echo '✅ Trivy Security Scan passed! No severe vulnerabilities found (or they were successfully ignored).'
            }
            post {
                always {
                    // Archive the Trivy report as a Jenkins artifact regardless of scan result
                    archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    // This is the URL generated by Terraform
                    env.ECR_URL = "867490540447.dkr.ecr.us-east-1.amazonaws.com"
                }
                echo '🔐 Authenticating to AWS ECR...'
                // Install AWS CLI if it is not already installed on the agent
                sh "if ! command -v aws &> /dev/null; then sudo apt-get update && sudo apt-get install -y awscli; fi"
                // This uses the IAM Instance Profile attached to the EC2 server (NO hardcoded passwords!)
                sh "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${env.ECR_URL}"
                
                echo '🚀 Pushing Images to ECR...'
                // Tag the local images with the remote ECR registry URL
                sh "docker tag sample-express-app:${env.SHORT_SHA} ${env.ECR_URL}/sample-express-app:${env.SHORT_SHA}"
                sh "docker tag sample-express-app:${env.CLEAN_BRANCH} ${env.ECR_URL}/sample-express-app:${env.CLEAN_BRANCH}"
                
                // Push both tags to AWS ECR
                sh "docker push ${env.ECR_URL}/sample-express-app:${env.SHORT_SHA}"
                sh "docker push ${env.ECR_URL}/sample-express-app:${env.CLEAN_BRANCH}"
                
                echo '✅ Images successfully pushed to AWS ECR!'
            }
        }

        stage('Deploy-Production (Blue-Green)') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo '🚀 Starting Blue-Green Deployment to AWS...'
                    
                    // 1. Query the ALB Listener to determine the currently LIVE color
                    env.ALB_ARN = sh(script: "aws elbv2 describe-load-balancers --names skillswap-web-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text", returnStdout: true).trim()
                    env.LISTENER_ARN = sh(script: "aws elbv2 describe-listeners --load-balancer-arn ${env.ALB_ARN} --query 'Listeners[?Port==`80`].ListenerArn' --output text", returnStdout: true).trim()
                    env.TEST_LISTENER_ARN = sh(script: "aws elbv2 describe-listeners --load-balancer-arn ${env.ALB_ARN} --query 'Listeners[?Port==`8080`].ListenerArn' --output text", returnStdout: true).trim()
                    
                    env.LIVE_TG_ARN = sh(script: "aws elbv2 describe-listeners --listener-arns ${env.LISTENER_ARN} --query 'Listeners[0].DefaultActions[0].TargetGroupArn' --output text", returnStdout: true).trim()
                    
                    if (env.LIVE_TG_ARN.contains('tg-blue')) {
                        env.LIVE_COLOR = 'blue'
                        env.IDLE_COLOR = 'green'
                    } else {
                        env.LIVE_COLOR = 'green'
                        env.IDLE_COLOR = 'blue'
                    }
                    
                    echo "🟢 Live Environment: ${env.LIVE_COLOR}"
                    echo "🟡 Idle Environment: ${env.IDLE_COLOR} (Will be updated)"
                    
                    env.IDLE_ASG = "skillswap-asg-${env.IDLE_COLOR}"
                    env.IDLE_TG_ARN = sh(script: "aws elbv2 describe-target-groups --names skillswap-tg-${env.IDLE_COLOR} --query 'TargetGroups[0].TargetGroupArn' --output text", returnStdout: true).trim()
                }
                
                // 2. Update the idle ASG Launch Template with the new ECR image
                sh '''
                    echo "📝 Updating Launch Template for ${IDLE_ASG}..."
                    LT_ID=$(aws ec2 describe-launch-templates --filters "Name=tag:Name,Values=Web-Server-Launch-Template" --query 'LaunchTemplates[0].LaunchTemplateId' --output text)
                    
                    # Create the new User Data script that pulls our new Docker image
                    USER_DATA=$(cat <<EOF
#!/bin/bash
set -euxo pipefail
yum update -y || apt-get update -y
yum install -y docker aws-cli || apt-get install -y docker.io awscli
systemctl start docker || true
systemctl enable docker || true

# Login to ECR and pull the newly built image
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 867490540447.dkr.ecr.us-east-1.amazonaws.com
# Run the application container on port 80 (mapping to Node.js port 3000)
docker run -d -p 80:3000 867490540447.dkr.ecr.us-east-1.amazonaws.com/sample-express-app:${SHORT_SHA}
EOF
)
                    B64_USER_DATA=$(echo "$USER_DATA" | base64 -w 0)
                    
                    # Create the new template version
                    NEW_VERSION=$(aws ec2 create-launch-template-version \
                      --launch-template-id $LT_ID \
                      --source-version '$Latest' \
                      --launch-template-data '{"UserData":"'"$B64_USER_DATA"'"}' \
                      --query 'LaunchTemplateVersion.VersionNumber' --output text)
                      
                    echo "✅ Created Launch Template Version: $NEW_VERSION"
                    
                    # Trigger an Instance Refresh to cycle out old EC2 instances
                    echo "🔄 Starting Instance Refresh on ${IDLE_ASG}..."
                    aws autoscaling start-instance-refresh \
                      --auto-scaling-group-name $IDLE_ASG \
                      --preferences '{"MinHealthyPercentage": 0}' \
                      --desired-configuration '{"LaunchTemplate": {"LaunchTemplateId": "'$LT_ID'", "Version": "'$NEW_VERSION'"}}'
                      
                    # Wait for Instance Refresh to complete
                    while true; do
                      STATUS=$(aws autoscaling describe-instance-refreshes --auto-scaling-group-name $IDLE_ASG --query 'InstanceRefreshes[0].Status' --output text)
                      if [ "$STATUS" == "Successful" ]; then break; fi
                      if [[ "$STATUS" == *"Failed"* ]] || [[ "$STATUS" == *"Cancelled"* ]]; then echo "❌ Refresh failed: $STATUS"; exit 1; fi
                      echo "⏳ Waiting for instance refresh... Status: $STATUS"
                      sleep 15
                    done
                    echo "✅ Instance Refresh Complete!"
                '''
                
                // 3. Wait for all targets to be healthy
                sh '''
                    echo "🏥 Waiting for targets in ${IDLE_TG_ARN} to become Healthy..."
                    aws elbv2 wait target-in-service --target-group-arn $IDLE_TG_ARN
                    echo "✅ All targets are healthy!"
                '''
                
                // 4. Run Smoke Test
                sh '''
                    echo "💨 Running Smoke Test on Idle Environment via Port 8080..."
                    ALB_DNS=$(aws elbv2 describe-load-balancers --names skillswap-web-alb --query 'LoadBalancers[0].DNSName' --output text)
                    
                    # Ensure Test Listener is pointing to IDLE_TG before testing
                    aws elbv2 modify-listener --listener-arn $TEST_LISTENER_ARN \
                      --default-actions Type=forward,TargetGroupArn=$IDLE_TG_ARN > /dev/null
                      
                    # Give it 10 seconds to propagate
                    sleep 10
                    
                    # Curl the test port
                    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$ALB_DNS:8080/)
                    if [ "$HTTP_STATUS" -eq 200 ]; then
                        echo "❌ Smoke test failed! Received HTTP status $HTTP_STATUS. Build will fail and listener will NOT be switched."
                        exit 1
                    fi
                    echo "✅ Smoke test passed! (HTTP $HTTP_STATUS)"
                '''
                
                // 5. Swap Traffic (Requirement 1 & 2)
                script {
                    env.TIMESTAMP = sh(script: "date -u +'%Y-%m-%dT%H:%M:%SZ'", returnStdout: true).trim()
                }
                sh '''
                    echo "🔀 Smoke test passed. Switching production traffic to ${IDLE_COLOR}..."
                    
                    # Point Main Listener (Port 80) to the new Live environment (previously Idle)
                    aws elbv2 modify-listener --listener-arn $LISTENER_ARN \
                      --default-actions Type=forward,TargetGroupArn=$IDLE_TG_ARN > /dev/null
                      
                    echo "✅ Traffic successfully switched. Production is now running on ${IDLE_COLOR}!"
                '''
                
                // 6. Log Deployment to S3 (Requirement 4)
                sh '''
                    echo "📝 Writing deployment log to S3..."
                    BUCKET="s3://skillswap-867490540447-us-east-1-3737/deployment-logs/deployments.jsonl"
                    LOG_FILE="deployments.jsonl"
                    
                    # Try to download the existing log file (it may not exist on the first run)
                    aws s3 cp $BUCKET $LOG_FILE || touch $LOG_FILE
                    
                    # Create the JSON log entry
                    JSON_LOG=$(printf '{"timestamp": "%s", "git_sha": "%s", "image_tag": "%s", "previous_color": "%s", "new_color": "%s", "result": "success"}' "$TIMESTAMP" "$SHORT_SHA" "$CLEAN_BRANCH" "$LIVE_COLOR" "$IDLE_COLOR")
                    
                    # Append the new entry
                    echo "$JSON_LOG" >> $LOG_FILE
                    
                    # Upload it back to S3
                    aws s3 cp $LOG_FILE $BUCKET
                    echo "✅ Deployment logged successfully!"
                '''
            }
            post {
                failure {
                    script {
                        env.TIMESTAMP = sh(script: "date -u +'%Y-%m-%dT%H:%M:%SZ'", returnStdout: true).trim()
                    }
                    sh '''
                        echo "📝 Writing FAILED deployment log to S3..."
                        BUCKET="s3://skillswap-867490540447-us-east-1-3737/deployment-logs/deployments.jsonl"
                        LOG_FILE="deployments.jsonl"
                        aws s3 cp $BUCKET $LOG_FILE || touch $LOG_FILE
                        
                        JSON_LOG=$(printf '{"timestamp": "%s", "git_sha": "%s", "image_tag": "%s", "previous_color": "%s", "new_color": "%s", "result": "failed"}' "$TIMESTAMP" "$SHORT_SHA" "$CLEAN_BRANCH" "$LIVE_COLOR" "$IDLE_COLOR")
                        echo "$JSON_LOG" >> $LOG_FILE
                        aws s3 cp $LOG_FILE $BUCKET
                    '''
                }
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
