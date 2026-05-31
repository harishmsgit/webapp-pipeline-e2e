#!/usr/bin/env bash
# Create S3 bucket and DynamoDB lock table for Terraform backend.
# Usage: ./create-terraform-backend.sh <BUCKET_NAME> <DYNAMODB_TABLE> <REGION>

set -euo pipefail
BUCKET_NAME=${1:-my-terraform-state-bucket}
TABLE_NAME=${2:-my-terraform-lock-table}
REGION=${3:-ap-south-1}

# Create S3 bucket if not exists
if ! aws s3api head-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" 2>/dev/null; then
  echo "Creating S3 bucket: ${BUCKET_NAME} in ${REGION}"
  aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" --create-bucket-configuration LocationConstraint=${REGION}
else
  echo "S3 bucket already exists: ${BUCKET_NAME}"
fi

# Create DynamoDB table if not exists
if ! aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${REGION}" 2>/dev/null; then
  echo "Creating DynamoDB table: ${TABLE_NAME}"
  aws dynamodb create-table \
    --table-name "${TABLE_NAME}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"
else
  echo "DynamoDB table already exists: ${TABLE_NAME}"
fi

echo "Backend resources ensured: S3=${BUCKET_NAME}, DynamoDB=${TABLE_NAME}"
