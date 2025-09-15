output "trail_name" {
  description = "Name of the CloudTrail"
  value       = aws_cloudtrail.this.name
}

output "bucket_id" {
  description = "CloudTrail log bucket ID"
  value       = aws_s3_bucket.trail.id
}

