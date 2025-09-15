variable "project" {
  description = "Project name used for tagging and resource naming"
  type        = string
}

variable "env" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
}

variable "trail_name" {
  description = "Optional override for the CloudTrail trail name"
  type        = string
  default     = null
}

