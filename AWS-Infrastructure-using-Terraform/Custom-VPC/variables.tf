variable "my_ip_cidr" {
  description = "Your public IP in CIDR format, for example 203.0.113.10/32"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for both web and DB instances"
  type        = string

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "instance_type must be one of: t3.micro, t3.small, t3.medium."
  }
}

variable "ami_id" {
  description = "AMI ID used for both EC2 instances"
  type        = string
}

variable "key_name" {
  description = "Name for the AWS key pair that Terraform creates"
  type        = string
}
