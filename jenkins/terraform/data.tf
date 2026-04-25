# Look up the existing VPC by its tag Name
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Name"
    values = ["SkillSwap-VPC"] # This matches the tag from your Assignment 3
  }
}

# Look up the existing Public Subnet by its tag Name
data "aws_subnet" "public_subnet" {
  filter {
    name   = "tag:Name"
    values = ["Public-Subnet-1"] # This matches the tag from your Assignment 3
  }
}

# Look up the existing Private Subnet by its tag Name
data "aws_subnet" "private_subnet" {
  filter {
    name   = "tag:Name"
    values = ["Private-Subnet-1"] # This matches the tag from your Assignment 3
  }
}

# Dynamically fetch the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
