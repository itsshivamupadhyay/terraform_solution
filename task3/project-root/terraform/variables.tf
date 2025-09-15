variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name prefix"
  type        = string
  default     = "spintech"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

