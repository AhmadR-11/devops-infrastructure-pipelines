# 1. Security Group for Jenkins Controller
resource "aws_security_group" "jenkins_controller_sg" {
  name        = "jenkins-controller-sg"
  description = "Security group for Jenkins Controller"
  vpc_id      = data.aws_vpc.existing_vpc.id 

  # Port 22 for SSH
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Port 8080 for Jenkins Web UI (Restricted to your IP)
  ingress {
    description = "Jenkins Web UI access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["59.103.246.18/32"] 
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins-Controller-SG"
  }
}

# 2. EC2 Instance for Jenkins Controller
resource "aws_instance" "jenkins_controller" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id                   = data.aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.jenkins_controller_sg.id]
  associate_public_ip_address = true

  # The user_data script runs automatically when the instance boots up for the first time.
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y

    # 1. Install Java 21 (Required for modern Jenkins)
    # Note: Your assignment PDF asked for Java 17, but Jenkins recently made an update requiring Java 21 minimum.
    sudo apt-get install -y openjdk-21-jre

    # 2. Install Jenkins LTS
    sudo mkdir -p /etc/apt/keyrings
    sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y jenkins
    sudo systemctl enable jenkins
    sudo systemctl start jenkins

    # 3. Install Git
    sudo apt-get install -y git

    # 4. Install Docker
    sudo apt-get install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
    # Add ubuntu and jenkins users to the docker group so they can run containers
    sudo usermod -aG docker ubuntu
    sudo usermod -aG docker jenkins

    # 5. Install AWS CLI
    sudo apt-get install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # 6. Install Terraform
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update -y
    sudo apt-get install -y terraform
  EOF

  tags = {
    Name = "Jenkins-Controller"
  }
}

# 3. Output the Public IP
output "jenkins_controller_public_ip" {
  description = "Public IP of the Jenkins Controller"
  value       = aws_instance.jenkins_controller.public_ip
}
