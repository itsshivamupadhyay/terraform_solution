#!/bin/bash
set -e

AWS_REGION="us-east-1"
BASE_BUCKET_NAME="spintech-terraform-state"
DDB_TABLE="terraform-locks"

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="${BASE_BUCKET_NAME}-${ACCOUNT_ID}"

echo "Using backend bucket: $BUCKET_NAME"
echo "Using DynamoDB table: $DDB_TABLE"

# Create backend bucket if needed
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "Creating S3 bucket: $BUCKET_NAME ..."
  if [ "$AWS_REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION"
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION"
  fi
fi

# Enable versioning on backend bucket
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# Create DynamoDB table if not exists
if ! aws dynamodb describe-table --table-name "$DDB_TABLE" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "Creating DynamoDB table: $DDB_TABLE ..."
  aws dynamodb create-table \
    --table-name "$DDB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION"
fi

# Path to main.tf (expect script inside terraform directory)
SCRIPT_DIR=$(dirname "$(realpath "$0")")
TF_MAIN="$SCRIPT_DIR/main.tf"

# Update ONLY backend block in main.tf
echo "Updating backend block in $TF_MAIN ..."
awk -v bucket="$BUCKET_NAME" -v region="$AWS_REGION" -v ddb="$DDB_TABLE" '
  /backend "s3" {/ { in_backend=1 }
  in_backend && /bucket/ { sub(/=.*/, "= \"" bucket "\"") }
  in_backend && /region/ { sub(/=.*/, "= \"" region "\"") }
  in_backend && /dynamodb_table/ { sub(/=.*/, "= \"" ddb "\"") }
  in_backend && /}/ { in_backend=0 }
  { print }
' "$TF_MAIN" > "$TF_MAIN.tmp" && mv "$TF_MAIN.tmp" "$TF_MAIN"

echo "✅ Backend configured with bucket: $BUCKET_NAME and table: $DDB_TABLE"

