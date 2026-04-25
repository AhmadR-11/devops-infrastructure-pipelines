#############################################################
# EC2 Launch Template
#
# Purpose:
# - Defines a reusable EC2 launch configuration for web-tier
#   instances in this assignment.
# - Uses the assignment AMI, fixed instance type `t3.micro`,
#   Task 2 SSH key pair, and the existing web server SG.
#############################################################

resource "aws_launch_template" "web_server_lt" {
  # Name prefix lets AWS append a unique suffix automatically.
  name_prefix = "skillswap-web-lt-"

  # Reuse the AMI already provided to this stack.
  image_id = var.ami_id

  # Assignment requirement: instance type must be t3.micro.
  instance_type = "t3.micro"

  # Use the key pair created in Task 2 (`aws_key_pair.generated_key`).
  key_name = aws_key_pair.generated_key.key_name

  # Attach the same security group used by the web server EC2.
  vpc_security_group_ids = [aws_security_group.web_server_sg.id] # Web SG allows HTTP/HTTPS/SSH per your SG rules.

  # Keep IAM access behavior consistent with your web server.
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_s3_profile.name
  }

  # Install stress-ng and Nginx during instance boot.
  # Launch Template user_data should be base64-encoded.
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -euxo pipefail

              dnf update -y || yum update -y
              dnf install -y nginx curl stress-ng || yum install -y nginx curl stress-ng

              systemctl enable nginx
              systemctl start nginx

              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
                -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
                http://169.254.169.254/latest/meta-data/instance-id)

              cat > /usr/share/nginx/html/index.html <<HTML
              <html>
              <body>
                <h1>Web Server is Running</h1>
                <p>Instance ID: $INSTANCE_ID</p>
              </body>
              </html>
              HTML

              systemctl restart nginx
              EOF
  )

  # Ensure new template versions are created before old ones are destroyed.
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name      = "Web-Server-Launch-Template"
    ManagedBy = "Terraform"
  }
}

output "web_server_launch_template_id" {
  description = "ID of the web server launch template."
  value       = aws_launch_template.web_server_lt.id
}

output "web_server_launch_template_latest_version" {
  description = "Latest version number of the web server launch template."
  value       = aws_launch_template.web_server_lt.latest_version
}
