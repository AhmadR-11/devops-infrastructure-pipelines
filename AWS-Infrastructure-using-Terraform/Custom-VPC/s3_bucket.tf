#############################################
# S3 Bucket (Unique Name with Roll Suffix)
#
# This file creates an S3 bucket with a globally
# unique name by combining:
# - AWS account ID
# - AWS region
# - your roll-number suffix (input variable)
#
# You can change `roll_number_suffix` in your
# `terraform.tfvars` file.
#############################################

# Fetch current AWS account details so bucket naming
# can include account ID for global uniqueness.
data "aws_caller_identity" "current" {}

# Fetch current AWS region so naming is environment-aware.
data "aws_region" "current" {}

# Roll number suffix requested in assignment.
# Example: "22f-1234"
variable "roll_number_suffix" {
  description = "Roll number (or any unique student suffix) appended to the S3 bucket name."
  type        = string
  default     = "3737"

  validation {
    condition     = length(var.roll_number_suffix) >= 3
    error_message = "roll_number_suffix must be at least 3 characters."
  }
}

locals {
  # Build a deterministic, globally-unique-ish bucket name.
  # S3 names must be lowercase and can contain letters, numbers, and hyphens.
  # We sanitize underscores to hyphens for safety.
  unique_bucket_name = lower(replace("skillswap-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-${var.roll_number_suffix}", "_", "-"))

  # DynamoDB table name used for Terraform state locking.
  # Keeping roll number in the name avoids collisions in shared accounts.
  tf_lock_table_name = lower(replace("skillswap-tf-lock-${var.roll_number_suffix}", "_", "-"))
}

# Create the S3 bucket using the unique local value.
resource "aws_s3_bucket" "assignment_bucket" {
  bucket = local.unique_bucket_name # final unique bucket name

  force_destroy = true

  tags = {
    Name        = "Assignment-S3-Bucket"
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

# Keep bucket private by blocking all public ACLs and policies.
resource "aws_s3_bucket_public_access_block" "assignment_bucket_pab" {
  bucket = aws_s3_bucket.assignment_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for better object recovery.
resource "aws_s3_bucket_versioning" "assignment_bucket_versioning" {
  bucket = aws_s3_bucket.assignment_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable default server-side encryption (SSE-S3 / AES256).
resource "aws_s3_bucket_server_side_encryption_configuration" "assignment_bucket_encryption" {
  bucket = aws_s3_bucket.assignment_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -------------------------------------------------------------
# IAM role for EC2 to access ONLY this S3 bucket
# -------------------------------------------------------------

# Trust policy: allows EC2 service to assume this role.
data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Role attached to EC2 through an instance profile.
resource "aws_iam_role" "ec2_s3_role" {
  name               = "ec2-s3-assignment-role-${var.roll_number_suffix}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

# Access policy: permit read/write to this bucket only.
data "aws_iam_policy_document" "ec2_s3_bucket_only_policy_doc" {
  statement {
    sid = "AllowListBucketOnlyForTargetBucket"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.assignment_bucket.arn
    ]
  }

  statement {
    sid = "AllowObjectReadWriteOnlyForTargetBucket"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.assignment_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "ec2_s3_bucket_only_policy" {
  name   = "ec2-s3-bucket-only-policy-${var.roll_number_suffix}"
  policy = data.aws_iam_policy_document.ec2_s3_bucket_only_policy_doc.json
}

# Attach the custom S3 policy to the role.
resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attachment" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.ec2_s3_bucket_only_policy.arn
}

# Instance profile is required to attach IAM role to EC2 instances.
resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2-s3-profile-${var.roll_number_suffix}"
  role = aws_iam_role.ec2_s3_role.name
}

# -------------------------------------------------------------
# DynamoDB table for Terraform remote state locking
# -------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = local.tf_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "Terraform-State-Lock-Table"
    ManagedBy = "Terraform"
  }
}

# Helpful output to quickly see the created bucket name.
output "assignment_s3_bucket_name" {
  description = "Globally unique S3 bucket name created for the assignment."
  value       = aws_s3_bucket.assignment_bucket.bucket
}

output "terraform_lock_table_name" {
  description = "DynamoDB table used to lock Terraform state operations."
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "ec2_s3_role_name" {
  description = "IAM role attached to EC2 for bucket-only access."
  value       = aws_iam_role.ec2_s3_role.name
}
