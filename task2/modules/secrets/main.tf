locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
  }
}

# Create a KMS key for Secrets Manager
resource "aws_kms_key" "this" {
  description             = "KMS CMK for Secrets Manager"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = local.tags
}

resource "aws_kms_alias" "alias" {
  name          = "alias/${local.name}-secrets"
  target_key_id = aws_kms_key.this.key_id
}

# Create a sample secret
resource "aws_secretsmanager_secret" "this" {
  name = "${var.project}-${var.env}-app-secret-${random_string.suffix.result}"
  description = "App secret for ${var.project}-${var.env}"
  kms_key_id  = aws_kms_key.this.arn
  tags        = local.tags
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Optional: add an initial secret value
resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({ username = "admin", password = "ChangeMe123!" })
}

