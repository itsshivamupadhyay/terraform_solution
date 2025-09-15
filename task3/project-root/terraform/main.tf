terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "spintech-terraform-state-430941623067"
    key            = "lambda/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Get AWS account ID for unique naming
data "aws_caller_identity" "current" {}

# -----------------------
# S3 Bucket for Lambda Data
# -----------------------
resource "aws_s3_bucket" "data_bucket" {
  bucket = "my-super-cool-bucket-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project}-lambda-data-bucket"
    Environment = var.environment
  }
}

# -----------------------
# IAM Role for Lambda
# -----------------------
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "${var.project}-lambda-s3-policy"
  description = "Allow Lambda to access S3 bucket objects"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:GetObject", "s3:PutObject"],
      Resource = "${aws_s3_bucket.data_bucket.arn}/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------
# Lambda Function
# -----------------------
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda/lambda.zip"
}

resource "aws_lambda_function" "this" {
  function_name = "${var.project}-lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.9"

  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_package.output_path)

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.data_bucket.bucket
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_attach]
}

