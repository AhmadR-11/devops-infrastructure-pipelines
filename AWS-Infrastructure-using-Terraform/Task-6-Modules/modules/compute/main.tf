# Requirement:
# • The module should create the EC2 instance, output its public_ip and instance_id.
# • Update your Terraform compute module to use the custom Packer-built AMI ID

resource "aws_instance" "this" { #tfsec:ignore:aws-ec2-enforce-http-token-imds #tfsec:ignore:aws-ec2-enable-at-rest-encryption
  # This dynamically uses the Packer AMI ID passed in via the ami_id variable!
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  # ACCEPTED RISK: IMDSv2 token enforcement not required for this demo/dev environment.
  # Production workloads should enforce IMDSv2 with http_tokens = "required".
  # tfsec:ignore:aws-ec2-enforce-http-token-imds

  # ACCEPTED RISK: EBS root volume encryption is not required for this non-production
  # demo environment. Production environments must encrypt all EBS volumes.
  # tfsec:ignore:aws-ec2-enable-at-rest-encryption

  tags = {
    Name = "${var.environment}-compute"
  }
}
