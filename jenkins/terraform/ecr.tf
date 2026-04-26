# Create a private ECR repository for our application
resource "aws_ecr_repository" "sample_app_repo" {
  name                 = "sample-express-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "sample-express-app-repo"
  }
}

# Attach a Lifecycle Policy to manage image retention
resource "aws_ecr_lifecycle_policy" "sample_app_repo_policy" {
  repository = aws_ecr_repository.sample_app_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep the 10 most recent images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.sample_app_repo.repository_url
  description = "The URL of the AWS ECR repository"
}
