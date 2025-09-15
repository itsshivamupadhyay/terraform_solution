variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "log_group_name" {
  type        = string
  description = "The CloudWatch log group where CloudTrail is writing logs"
}

locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
  }
}

# ──────────────────────────────
# Metric Filter for Unauthorized Actions
# ──────────────────────────────
resource "aws_cloudwatch_log_metric_filter" "unauth" {
  name           = "${local.name}-unauth-metric"
  log_group_name = var.log_group_name

  # Capture AccessDenied and UnauthorizedOperation errors
  pattern = <<EOF
{ ($.errorCode = "*UnauthorizedOperation") || ($.errorCode = "AccessDenied*") }
EOF

  metric_transformation {
    name      = "${local.name}-unauth-count"
    namespace = "Security"
    value     = "1"
  }
}

# ──────────────────────────────
# CloudWatch Alarm
# ──────────────────────────────
resource "aws_cloudwatch_metric_alarm" "unauth" {
  alarm_name          = "${local.name}-unauthorized-api"
  alarm_description   = "Triggers when unauthorized/denied API calls are detected by CloudTrail."
  namespace           = "Security"
  metric_name         = aws_cloudwatch_log_metric_filter.unauth.metric_transformation[0].name
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"
  tags               = local.tags

  # Optional: send notification to an SNS topic
  # alarm_actions = [aws_sns_topic.security_alerts.arn]
}

