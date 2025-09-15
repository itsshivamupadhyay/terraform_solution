output "bucket_id" {
  description = "S3 bucket for AWS Config logs"
  value       = try(aws_s3_bucket.config[0].id, null)
}

output "role_name" {
  description = "IAM role name for AWS Config"
  value       = try(aws_iam_role.config[0].name, null)
}

