# Requirement:
# • Create a modules/compute/ module that accepts: ami_id, instance_type, subnet_id,
# security_group_ids, key_name, and environment.

variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "subnet_id" { type = string }
variable "security_group_ids" { type = list(string) }
variable "key_name" { type = string }
variable "environment" { type = string }
