# Requirement:
# • Create a modules/vpc/ directory containing a self-contained VPC module with inputs for:
# vpc_cidr, public_subnet_cidrs (list), private_subnet_cidrs (list), and environment (string).

variable "vpc_cidr" {
  type = string
}
variable "public_subnet_cidrs" {
  type = list(string)
}
variable "private_subnet_cidrs" {
  type = list(string)
}
variable "environment" {
  type = string
}
