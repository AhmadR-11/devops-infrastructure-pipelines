# Requirement:
# • Call the module from your root main.tf and pass appropriate values.

provider "aws" {
  region = "us-east-1"
}

# 1. Calling VPC Module
module "vpc" {
  source               = "./modules/vpc"
  environment          = "skillswap-task6"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}

# 2. Calling Security Module
module "security" {
  source      = "./modules/security"
  environment = "skillswap-task6"
  vpc_id      = module.vpc.vpc_id
}

# Dummy key temporarily for the module demo
resource "tls_private_key" "key" {
  algorithm = "RSA"
}
resource "aws_key_pair" "key" {
  key_name   = "task6-modular-key"
  public_key = tls_private_key.key.public_key_openssh
}

# 3. Calling Compute Module
module "compute" {
  source      = "./modules/compute"
  environment = "skillswap-task6"

  # Requirement:
  # • Update your Terraform compute module to use the custom Packer-built AMI ID
  # ONCE PACKER IS BUILT, PASTE THE AMI HERE!
  ami_id = "ami-PLACEHOLDER_REPLACE_ME_AFTER_PACKER_BUILD"

  instance_type      = "t3.micro"
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.security.web_sg_id]
  key_name           = aws_key_pair.key.key_name
}
