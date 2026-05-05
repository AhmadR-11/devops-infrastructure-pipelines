# Security Group for SonarQube
resource "aws_security_group" "sonarqube_sg" {
  name        = "sonarqube-sg"
  description = "Allow port 9000 for SonarQube UI and 22 for SSH"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # Port 9000 for SonarQube Web UI (Open to all - dynamic IP workaround)
  ingress {
    description = "SonarQube Web UI - Public Access"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 9000 for SonarQube Web UI (Restricted to Jenkins Agent & Controller)
  ingress {
    description     = "SonarQube Web UI from Jenkins"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_agent_sg.id, aws_security_group.jenkins_controller_sg.id]
  }

  # Port 22 for SSH
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SonarQube-SG"
  }
}

# EC2 Instance for SonarQube
resource "aws_instance" "sonarqube" {
  ami           = "ami-0ff290337e78c83bf" # Pinned to current running instance AMI to prevent replacement
  instance_type = "t3.small" # Reverted to t3.small due to AWS Academy limits
  subnet_id     = data.aws_subnet.public_subnet.id
  key_name      = "skillswap-new-key" # Uses the same SSH key as Jenkins

  vpc_security_group_ids = [aws_security_group.sonarqube_sg.id]

  # Increase the hard drive size to 15 GB because the swap file and docker images are heavy!
  root_block_device {
    volume_size = 15
    volume_type = "gp2"
  }

  # User data to install Docker, create SWAP space, fix memory limits, and start SonarQube
  user_data = <<-EOF
              #!/bin/bash
              # 1. Create a 2GB Swap file to prevent Out-Of-Memory crashes on t3.small!
              fallocate -l 2G /swapfile
              chmod 600 /swapfile
              mkswap /swapfile
              swapon /swapfile
              echo '/swapfile none swap sw 0 0' >> /etc/fstab
              
              # 2. Install Docker
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              
              # 3. Fix SonarQube Elasticsearch memory requirement
              sysctl -w vm.max_map_count=262144
              echo "vm.max_map_count=262144" >> /etc/sysctl.conf
              
              # 4. Start SonarQube using Docker
              docker run -d --name sonarqube -p 9000:9000 sonarqube:community
              EOF

  tags = {
    Name = "SonarQube-Server"
  }
}

# Print out the new SonarQube IP address when finished
output "sonarqube_public_ip" {
  value = aws_instance.sonarqube.public_ip
}
