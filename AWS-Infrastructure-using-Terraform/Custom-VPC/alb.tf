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
    from_port   = 80 # Opening Port 80 for HTTP connection
    to_port     = 80
    protocol    = "tcp" # HTTP uses TCP protocol
    cidr_blocks = ["0.0.0.0/0"] # 0.0.0.0/0 means "the entire internet"
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
  internal           = false # Set to false because this faces the public internet
  load_balancer_type = "application" # "application" balances HTTP/HTTPS. ("network" is for pure TCP/UDP)
  security_groups    = [aws_security_group.alb_sg.id] # Attach the SG we created right above
  
  # The ALB must exist in multiple Availability Zones for high availability
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "Web-ALB"
  }
}

# Requirement:
# • Create an aws_lb_target_group with protocol HTTP, port 80, and a health check on path /
# with healthy_threshold = 2 and unhealthy_threshold = 3.
resource "aws_lb_target_group" "web_tg" {
  name     = "skillswap-web-tg"
  port     = 80 # Send traffic to the EC2 instances on this port
  protocol = "HTTP"
  vpc_id   = aws_vpc.custom_vpc.id

  # Health Check block: The ALB will constantly ping the EC2 instances.
  # If an instance dies, the ALB stops sending traffic to it.
  health_check {
    path                = "/" # Ping the root index.html page
    protocol            = "HTTP"
    healthy_threshold   = 2 # Need 2 successful pings to be considered "healthy"
    unhealthy_threshold = 3 # Need 3 failed pings to be marked "sick/dead"
    interval            = 30 # Ping every 30 seconds
    timeout             = 5 # Wait 5 seconds for a response before timing out
  }

  tags = {
    Name = "Web-Target-Group"
  }
}

# Requirement:
# • Create an aws_lb_listener on port 80 that forwards traffic to the target group.
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn # Bind this listener to our ALB
  port              = "80" # Listen for users hitting port 80
  protocol          = "HTTP"

  # What to do when a request comes in:
  default_action {
    type             = "forward" # Forward the traffic...
    target_group_arn = aws_lb_target_group.web_tg.arn # ...directly to our Target Group!
  }
}

# Requirement:
# • Attach the Auto Scaling Group to the target group using aws_autoscaling_attachment
resource "aws_autoscaling_attachment" "asg_attachment" {
  # This dynamically tells the ASG: "Whenever you launch a new instance, 
  # register its IP address into this Load Balancer Target Group immediately."
  autoscaling_group_name = aws_autoscaling_group.web_asg.id 
  lb_target_group_arn    = aws_lb_target_group.web_tg.arn
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
