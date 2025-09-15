variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be deployed"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (for creating security group)"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile to attach"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name (optional)"
  type        = string
  default     = null
}

