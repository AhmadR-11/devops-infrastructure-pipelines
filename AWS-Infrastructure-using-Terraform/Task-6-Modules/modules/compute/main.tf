# Requirement:
# • The module should create the EC2 instance, output its public_ip and instance_id.
# • Update your Terraform compute module to use the custom Packer-built AMI ID

resource "aws_instance" "this" {
  # This dynamically uses the Packer AMI ID passed in via the ami_id variable!
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  tags = {
    Name = "${var.environment}-compute"
  }
}
