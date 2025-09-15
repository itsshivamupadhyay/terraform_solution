#!/usr/bin/env bash
set -euo pipefail
REGION=${1:-us-east-1}
BUCKET=${2:-shivam-terraform-statev1}
TABLE=${3:-terraform-locks}

aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null || {
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"         $( [ "$REGION" != "us-east-1" ] && echo --create-bucket-configuration LocationConstraint="$REGION" )
}
aws s3api put-bucket-encryption --bucket "$BUCKET" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" >/dev/null 2>&1 || {
  aws dynamodb create-table --table-name "$TABLE" --region "$REGION"         --attribute-definitions AttributeName=LockID,AttributeType=S         --key-schema AttributeName=LockID,KeyType=HASH         --billing-mode PAY_PER_REQUEST
}
echo "Backend ready: s3://$BUCKET and DynamoDB:$TABLE"

