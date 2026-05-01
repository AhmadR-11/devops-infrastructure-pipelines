#############################################################
# Terraform Remote State Backend - Task 6 Modules
#
# Reuses the same S3 bucket and DynamoDB lock table that
# was created in Assignment 3 (Custom-VPC task).
# A different 'key' path is used to keep the state separate.
#
# Benefits:
#   - State persists across Jenkins builds (not lost if agent restarts)
#   - DynamoDB locking prevents two concurrent pipeline runs from
#     corrupting state at the same time
#############################################################

terraform {
  backend "s3" {
    bucket     = "skillswap-867490540447-us-east-1-3737"
    key        = "task6-modules/terraform.tfstate"
    region     = "us-east-1"
    encrypt    = true
    # use_lockfile enables native S3 state locking (Terraform v1.10+)
    # This replaces the deprecated dynamodb_table parameter
    use_lockfile = true
  }
}

