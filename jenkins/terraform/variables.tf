variable "ami_id" {
  description = "AMI ID for Ubuntu"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Your AMI from Assignment 3
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  # NOTE: We use t3.medium here because Jenkins and Java need at least 4GB of RAM to run without crashing!
  default     = "t3.micro" 
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
  default     = "skillswap-new-key" # Your SSH key from Assignment 3
}
