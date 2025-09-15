 #!/usr/bin/env bash
set -euo pipefail

# Inputs with sane defaults
REGION=${1:-us-east-1}
BASE_BUCKET_NAME=${2:-shivam-terraform-statev1}
TABLE=${3:-terraform-locks}

# Ensure uniqueness: append AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="${BASE_BUCKET_NAME}-${ACCOUNT_ID}"

echo ">>> Using S3 bucket: $BUCKET"
echo ">>> Using DynamoDB table: $TABLE"
echo ">>> Region: $REGION"

# Create bucket if not exists
if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Creating bucket $BUCKET ..."
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET"
  else
    aws s3api create-bucket --bucket "$BUCKET" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "Bucket created. Waiting for stabilization..."
  sleep 10
else
  echo "Bucket $BUCKET already exists, skipping creation."
fi

# Always enforce encryption
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" }
      }
    ]
  }'

# Create DynamoDB table if not exists
if ! aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" >/dev/null 2>&1; then
  echo "Creating DynamoDB table $TABLE ..."
  aws dynamodb create-table \
    --table-name "$TABLE" \
    --region "$REGION" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
  echo "Waiting for DynamoDB table $TABLE to become active..."
  aws dynamodb wait table-exists --table-name "$TABLE" --region "$REGION"
else
  echo "DynamoDB table $TABLE already exists, skipping creation."
fi

# Generate provider.tf with backend + providers
cat > provider.tf <<EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET"
    key            = "task2/terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "$TABLE"
    encrypt        = true
  }

  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
EOF

echo "✅ Backend ready: s3://$BUCKET (state), DynamoDB:$TABLE (locking)"
echo "✅ provider.tf generated successfully"

