# Requirement:
# • Install Packer and write a Packer HCL template (build.pkr.hcl) that: starts from the base
# Ubuntu AMI, installs Nginx and curl, creates a custom /var/www/html/index.html
# displaying a welcome message, and saves the result as a custom AMI in your AWS
# account.

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "skillswap-packer-nginx-{{timestamp}}"
  instance_type = "t3.micro"
  region        = "us-east-1"
  
  # Grab the officially maintained Canonical Ubuntu 22.04 base image
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical Official AWS Account ID
  }
  
  ssh_username = "ubuntu"
}

build {
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  # Provisioning Steps
  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      # Install Nginx and Curl
      "sudo apt-get install -y nginx curl",
      
      # Create custom index.html displaying welcome message
      "echo '<html><body><h1>Welcome to SkillSwap Custom Packer Image!</h1></body></html>' | sudo tee /var/www/html/index.html",
      
      # Enable and start Nginx service
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx"
    ]
  }
}
