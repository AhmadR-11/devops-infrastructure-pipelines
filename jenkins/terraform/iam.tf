# IAM Role for the Jenkins Agent
resource "aws_iam_role" "jenkins_agent_role" {
  name = "jenkins_agent_ecr_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy that grants access to push and pull from ECR
resource "aws_iam_policy" "ecr_access_policy" {
  name        = "JenkinsAgentECRAccessPolicy"
  description = "Allows Jenkins Agent to authenticate, push, and pull images from the ECR repository"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        # GetAuthorizationToken must apply to all resources ("*")
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        # Restrict the actual push/pull permissions to our specific repository
        Resource = aws_ecr_repository.sample_app_repo.arn
      }
    ]
  })
}

# IAM Policy that grants Terraform access to S3 state backend + DynamoDB locking
# Required so the infra-pipeline can store and lock Terraform state remotely.
# Without this, terraform init fails with a 403 Forbidden error.
resource "aws_iam_policy" "terraform_state_policy" {
  name        = "JenkinsAgentTerraformStatePolicy"
  description = "Allows Jenkins Agent to read/write Terraform state in S3 and lock it via DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # S3 permissions scoped to the specific state bucket only
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = [
          "arn:aws:s3:::skillswap-867490540447-us-east-1-3737",
          "arn:aws:s3:::skillswap-867490540447-us-east-1-3737/*"
        ]
      },
      {
        # DynamoDB permissions for Terraform state locking
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:us-east-1:867490540447:table/skillswap-tf-lock-3737"
      }
    ]
  })
}

# Attach the ECR Policy to the Role
resource "aws_iam_role_policy_attachment" "jenkins_agent_ecr_attach" {
  role       = aws_iam_role.jenkins_agent_role.name
  policy_arn = aws_iam_policy.ecr_access_policy.arn
}

# Attach the Terraform State Policy to the Role
resource "aws_iam_role_policy_attachment" "jenkins_agent_terraform_state_attach" {
  role       = aws_iam_role.jenkins_agent_role.name
  policy_arn = aws_iam_policy.terraform_state_policy.arn
}

# IAM Policy that grants access for Blue-Green Deployment AWS CLI operations
resource "aws_iam_policy" "blue_green_deploy_policy" {
  name        = "JenkinsAgentBlueGreenDeployPolicy"
  description = "Allows Jenkins Agent to perform ALB, ASG, and EC2 updates for Blue-Green deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:DescribeTargetHealth",
          "ec2:DescribeLaunchTemplates",
          "ec2:CreateLaunchTemplateVersion",
          "autoscaling:StartInstanceRefresh",
          "autoscaling:DescribeInstanceRefreshes"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach Blue-Green Deployment Policy
resource "aws_iam_role_policy_attachment" "jenkins_agent_blue_green_attach" {
  role       = aws_iam_role.jenkins_agent_role.name
  policy_arn = aws_iam_policy.blue_green_deploy_policy.arn
}

# Create an Instance Profile to wrap the Role so it can be attached to the EC2 Instance
resource "aws_iam_instance_profile" "jenkins_agent_profile" {
  name = "jenkins_agent_instance_profile"
  role = aws_iam_role.jenkins_agent_role.name
}
