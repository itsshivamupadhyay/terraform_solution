output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "s3_bucket_name" {
  description = "The S3 bucket name used by Lambda"
  value       = aws_s3_bucket.data_bucket.bucket
}

