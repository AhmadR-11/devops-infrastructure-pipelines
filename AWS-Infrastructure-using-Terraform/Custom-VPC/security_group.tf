# -------------------------------------------------------------
# SECURITY GROUP (PUBLIC WEB SERVER)
# Allows HTTP, HTTPS and SSH from your IP only.
# -------------------------------------------------------------
resource "aws_security_group" "web_server_sg" {
  name        = "web-server-public-sg"
  description = "Allow HTTP, HTTPS, and SSH from my IP only"
  vpc_id      = aws_vpc.custom_vpc.id

  # Requirement:
  # • Modify the EC2 instance Security Group from Task 2 to only allow HTTP traffic from the
  # ALB Security Group, not from the internet directly
  ingress {
    description     = "HTTP from ALB SG only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "HTTPS from my IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-Server-SG"
  }
}

# -------------------------------------------------------------
# SECURITY GROUP (PRIVATE DATABASE SERVER)
# 3306 is allowed only from the web server SG.
# 22 is also allowed only from the web server SG to support bastion SSH tests.
# -------------------------------------------------------------
resource "aws_security_group" "db_server_sg" {
  name        = "db-server-private-sg"
  description = "Allow MySQL and SSH only from web server security group"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description     = "MySQL from web server SG only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server_sg.id]
  }

  ingress {
    description     = "SSH from web server SG only (bastion pattern)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DB-Server-SG"
  }
}
