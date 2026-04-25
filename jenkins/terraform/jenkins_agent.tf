# Security Group for Jenkins Agent
resource "aws_security_group" "jenkins_agent_sg" {
  name        = "jenkins-agent-sg"
  description = "Security group for Jenkins Agent"
  vpc_id      = data.aws_vpc.existing_vpc.id

  # Allow SSH ONLY from the Jenkins Controller
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_controller_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jenkins-Agent-SG"
  }
}

# Jenkins Agent EC2 Instance
resource "aws_instance" "jenkins_agent" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.private_subnet.id
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.jenkins_agent_sg.id]

  # Install Java 21, Git, and Docker (needed for agent to run pipeline steps)
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y openjdk-21-jre git docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
    # Add ubuntu user to the docker group so pipelines can run containers
    sudo usermod -aG docker ubuntu
  EOF

  tags = {
    Name = "linux-agent"
  }
}

output "jenkins_agent_private_ip" {
  value       = aws_instance.jenkins_agent.private_ip
  description = "The private IP address of the Jenkins Agent (Used by the controller to connect)"
}
