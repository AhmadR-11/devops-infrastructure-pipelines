#############################################################
# Terraform Remote State Backend
#
# IMPORTANT:
# Backend blocks cannot use variables/resources directly.
# So first create bucket + lock table once, then replace the
# placeholders below and run `terraform init -migrate-state`.
#############################################################

# terraform {
#   backend "s3" {
#     bucket         = "skillswap-867490540447-us-east-1-3737"
#     key            = "custom-vpc/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "skillswap-tf-lock-3737"
#     encrypt        = true
#   }
# }

