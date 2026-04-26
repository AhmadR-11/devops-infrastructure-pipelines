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

# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "jenkins_agent_ecr_attach" {
  role       = aws_iam_role.jenkins_agent_role.name
  policy_arn = aws_iam_policy.ecr_access_policy.arn
}

# Create an Instance Profile to wrap the Role so it can be attached to the EC2 Instance
resource "aws_iam_instance_profile" "jenkins_agent_profile" {
  name = "jenkins_agent_instance_profile"
  role = aws_iam_role.jenkins_agent_role.name
}
