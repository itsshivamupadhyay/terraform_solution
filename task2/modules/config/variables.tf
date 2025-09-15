variable "enabled" {
  description = "Whether to enable AWS Config"
  type        = bool
  default     = true
}

variable "project" {
  description = "Project name prefix"
  type        = string
}

variable "env" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

