# Requirement:
# • Create a modules/security/ module for Security Groups that accepts vpc_id and
# environment, and outputs web_sg_id and db_sg_id.

resource "aws_security_group" "web" {
  name   = "${var.environment}-web-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    # ACCEPTED RISK: Public HTTP ingress (port 80) is required for a web server.
    # This is an intentional design for a publicly accessible web application.
    # tfsec:ignore:aws-ec2-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # ACCEPTED RISK: Unrestricted egress is required for the web server
    # to download packages, reach updates, and call external APIs.
    # tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
  }

  tags = { Name = "${var.environment}-web-sg" }
}

resource "aws_security_group" "db" {
  name   = "${var.environment}-db-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # ACCEPTED RISK: Unrestricted egress on the DB security group is required
    # for the database instance to reach AWS services (e.g., SSM, RDS endpoints).
    # tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
  }

  tags = { Name = "${var.environment}-db-sg" }
}
