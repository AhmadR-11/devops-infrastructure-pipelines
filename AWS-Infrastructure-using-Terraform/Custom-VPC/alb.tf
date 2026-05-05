#############################################################
# Task 5: Elastic Load Balancer with Health Checks
#############################################################

# Requirement:
# • Create a dedicated Security Group for the ALB that allows inbound HTTP (80) from
# 0.0.0.0/0 and all outbound traffic.
resource "aws_security_group" "alb_sg" {
  name        = "skillswap-alb-sg" # Friendly name for AWS Console
  description = "Security group for Application Load Balancer allows HTTP from anywhere"
  vpc_id      = aws_vpc.custom_vpc.id # Ties this SG to your custom network

  # Ingress = Incoming traffic rules
  ingress {
    description = "Allow HTTP inbound from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Test HTTP inbound from anywhere"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress = Outgoing traffic rules
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0 # 0 means "all ports"
    to_port     = 0
    protocol    = "-1" # -1 means "all protocols" (TCP/UDP/etc)
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB-SG"
  }
}

# Requirement:
# • Create an aws_lb (ALB) of type application deployed across both public subnets.
resource "aws_lb" "web_alb" {
  name               = "skillswap-web-alb"
  internal           = false                          # Set to false because this faces the public internet
  load_balancer_type = "application"                  # "application" balances HTTP/HTTPS. ("network" is for pure TCP/UDP)
  security_groups    = [aws_security_group.alb_sg.id] # Attach the SG we created right above

  # The ALB must exist in multiple Availability Zones for high availability
  subnets = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "Web-ALB"
  }
}

# Requirement: Blue Target Group
resource "aws_lb_target_group" "tg_blue" {
  name     = "skillswap-tg-blue"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "Blue-Target-Group"
  }
}

# Requirement: Green Target Group
resource "aws_lb_target_group" "tg_green" {
  name     = "skillswap-tg-green"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "Green-Target-Group"
  }
}

# Main Production Listener (Port 80)
resource "aws_lb_listener" "blue_green_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # Initially point to Blue (100% traffic)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_blue.arn
  }

  # Ignore changes so Terraform doesn't revert the Jenkins deployments!
  lifecycle {
    ignore_changes = [default_action]
  }
}

# Idle/Test Listener (Port 8080) for Smoke Testing
resource "aws_lb_listener" "test_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "8080"
  protocol          = "HTTP"

  # Initially point to Green (Idle environment)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_green.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

# Requirement: Attach both ASGs to their respective Target Groups
resource "aws_autoscaling_attachment" "asg_attachment_blue" {
  autoscaling_group_name = aws_autoscaling_group.asg_blue.id
  lb_target_group_arn    = aws_lb_target_group.tg_blue.arn
}

resource "aws_autoscaling_attachment" "asg_attachment_green" {
  autoscaling_group_name = aws_autoscaling_group.asg_green.id
  lb_target_group_arn    = aws_lb_target_group.tg_green.arn
}

# Requirement:
# • Use curl or a browser to send multiple requests to the ALB DNS name and observe which
# instance responds (hint: display instance ID in the Nginx page).
# • Show that requests are being served by different instances, demonstrating load
# distribution.
# (This is manual verification, but we export the dns_name here to use for the curl command)
output "alb_dns_name" {
  description = "The DNS name of the ALB to paste into your browser"
  value       = aws_lb.web_alb.dns_name
}
