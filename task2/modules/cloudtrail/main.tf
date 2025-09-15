locals {
  name = coalesce(var.trail_name, "${var.project}-${var.env}-trail")
  tags = {
    Project = var.project
    Env     = var.env
  }
}

# ──────────────────────────────
# S3 Bucket for CloudTrail logs
# ──────────────────────────────
resource "aws_s3_bucket" "trail" {
  bucket        = "${var.project}-${var.env}-ct-logs"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "trail" {
  bucket = aws_s3_bucket.trail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket                  = aws_s3_bucket.trail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────
# S3 Bucket Policy for CloudTrail
# ──────────────────────────────
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "trail_bucket" {
  statement {
    sid = "AWSCloudTrailAclCheck"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail.arn]
  }

  statement {
    sid = "AWSCloudTrailWrite"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.trail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = data.aws_iam_policy_document.trail_bucket.json
}

# ──────────────────────────────
# CloudWatch Logs Integration
# ──────────────────────────────
resource "aws_cloudwatch_log_group" "trail" {
  name              = "/aws/cloudtrail/${var.project}-${var.env}"
  retention_in_days = 90
  tags              = local.tags
}

# IAM role that CloudTrail assumes to push logs into CloudWatch
data "aws_iam_policy_document" "trail_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "trail" {
  name               = "${var.project}-${var.env}-cloudtrail-role"
  assume_role_policy = data.aws_iam_policy_document.trail_assume.json
  tags               = local.tags
}

# Policy granting CloudTrail permissions to push logs
data "aws_iam_policy_document" "trail_to_cw" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.trail.arn}:*"]
  }
}

resource "aws_iam_role_policy" "trail_to_cw" {
  name   = "${var.project}-${var.env}-trail-cw"
  role   = aws_iam_role.trail.id
  policy = data.aws_iam_policy_document.trail_to_cw.json
}

# ──────────────────────────────
# CloudTrail Resource
# ──────────────────────────────
resource "aws_cloudtrail" "this" {
  name                          = local.name
  s3_bucket_name                = aws_s3_bucket.trail.id

  # 👇 FIXED: Must include :* for ARN validation
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.trail.arn

  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  tags                          = local.tags

  # 👇 Ensure resources are ready first
  depends_on = [
    aws_iam_role_policy.trail_to_cw,
    aws_s3_bucket_policy.trail,
    aws_cloudwatch_log_group.trail
  ]
}

