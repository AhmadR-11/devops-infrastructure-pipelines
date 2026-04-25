provider "aws" {
  region = "us-east-1"
}

# -------------------------------------------------------------
# 1. VPC & PUBLIC SUBNETS (Previously Built)
# -------------------------------------------------------------
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "SkillSwap-VPC" }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "Public-Subnet-1" }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "Public-Subnet-2" }
}


# -------------------------------------------------------------
# 2. PRIVATE SUBNETS
# Created in different Availability Zones without auto-assigning Public IPs.
# -------------------------------------------------------------
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false # Explicitly false so it remains private!
  tags                    = { Name = "Private-Subnet-1" }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags                    = { Name = "Private-Subnet-2" }
}


# -------------------------------------------------------------
# 3. INTERNET GATEWAY & PUBLIC ROUTE TABLE
# This connects the VPC to the outside internet and routes traffic out.
# -------------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id
  tags   = { Name = "SkillSwap-IGW" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  # Routes all internet-bound traffic (0.0.0.0/0) through the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "Public-Route-Table" }
}

# Associate the Public Route Table with the two Public Subnets
resource "aws_route_table_association" "public_rt_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_rt_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}


# -------------------------------------------------------------
# 4. NAT GATEWAY & ELASTIC IP
# Allows servers in Private Subnets to safely download updates from the internet.
# -------------------------------------------------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "SkillSwap-NAT-EIP" }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id # NAT GW must sit inside a Public Subnet

  # Requirement fulfilled: Explicitly wait for IGW to exist before creating NAT GW!
  depends_on = [aws_internet_gateway.igw]

  tags = { Name = "SkillSwap-NAT-GW" }
}


# -------------------------------------------------------------
# 5. PRIVATE ROUTE TABLE
# Secures the private subnets by routing their internet traffic purely through the NAT proxy.
# -------------------------------------------------------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "Private-Route-Table" }
}

# Associate the Private Route Table with the two Private Subnets
resource "aws_route_table_association" "private_rt_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_rt_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# -------------------------------------------------------------
# 7. OUTPUT BLOCKS
# Safely prints out values to the terminal after Terraform finishes loading.
# -------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the custom VPC"
  value       = aws_vpc.custom_vpc.id
}

output "public_subnet_ids" {
  description = "The IDs of the Public Subnets"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "private_subnet_ids" {
  description = "The IDs of the Private Subnets"
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.nat_gw.id
}

output "web_server_security_group_id" {
  description = "The ID of the web server security group"
  value       = aws_security_group.web_server_sg.id
}

output "db_security_group_id" {
  description = "The ID of the private DB security group"
  value       = aws_security_group.db_server_sg.id
}

output "web_instance_public_ip" {
  description = "Public IP of the web instance (use this for first SSH hop)"
  value       = aws_instance.web_server.public_ip
}

output "web_instance_id" {
  description = "The ID of the public web server instance"
  value       = aws_instance.web_server.id
}

output "db_instance_private_ip" {
  description = "Private IP of the DB instance (reachable from bastion/public instance)"
  value       = aws_instance.db_server.private_ip
}