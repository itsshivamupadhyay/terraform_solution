locals {
  name = "${var.project}-${var.env}-config"
  tags = {
    Project = var.project
    Env     = var.env
  }
}

# ──────────────────────────────
# S3 bucket for Config logs
# ──────────────────────────────
resource "aws_s3_bucket" "config" {
  count         = var.enabled ? 1 : 0
  bucket        = "${var.project}-${var.env}-config-logs"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "config" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.config[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.config[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  count                   = var.enabled ? 1 : 0
  bucket                  = aws_s3_bucket.config[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────
# IAM role for AWS Config
# ──────────────────────────────
data "aws_iam_policy_document" "config_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config" {
  count              = var.enabled ? 1 : 0
  name               = "${local.name}-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "config_policy" {
  statement {
    actions = [
      "s3:*",
      "config:*",
      "ec2:Describe*",
      "iam:List*",
      "iam:Get*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "config" {
  count  = var.enabled ? 1 : 0
  name   = "${local.name}-policy"
  role   = aws_iam_role.config[0].id
  policy = data.aws_iam_policy_document.config_policy.json
}

# ──────────────────────────────
# Config Recorder + Delivery Channel
# ──────────────────────────────
resource "aws_config_configuration_recorder" "this" {
  count    = var.enabled ? 1 : 0
  name     = "${local.name}-recorder"
  role_arn = aws_iam_role.config[0].arn
}

resource "aws_config_delivery_channel" "this" {
  count          = var.enabled ? 1 : 0
  name           = "${local.name}-delivery"
  s3_bucket_name = aws_s3_bucket.config[0].id

  # Ensure recorder exists first
  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "status" {
  count      = var.enabled ? 1 : 0
  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  # Ensure delivery channel is in place before enabling
  depends_on = [aws_config_delivery_channel.this]
}

