variable "vpc_id" {
  description = "VPC ID where security group will be created"
  type        = string
}

variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "env" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

