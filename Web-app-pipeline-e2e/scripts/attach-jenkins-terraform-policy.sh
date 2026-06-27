#!/usr/bin/env bash
# Attach the jenkins-terraform-policy.json to the specified IAM role.
# Usage: ./attach-jenkins-terraform-policy.sh <ROLE_NAME> <POLICY_NAME> <AWS_ACCOUNT_ID>

set -euo pipefail
ROLE_NAME=${1:-jenkins-sprint1-ec2-role}
POLICY_NAME=${2:-jenkins-terraform-policy}
AWS_ACCOUNT_ID=${3:-$(aws sts get-caller-identity --query Account --output text)}

POLICY_PATH="$(dirname "$0")/../jenkins-terraform-policy.json"

if [ ! -f "$POLICY_PATH" ]; then
  echo "Policy file not found at $POLICY_PATH"
  exit 1
fi

echo "Creating IAM policy ${POLICY_NAME} (if it doesn't exist)..."
EXISTING_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn | [0]" --output text || true)
if [ "$EXISTING_ARN" = "None" ] || [ -z "$EXISTING_ARN" ]; then
  CREATE_OUT=$(aws iam create-policy --policy-name "${POLICY_NAME}" --policy-document file://"$POLICY_PATH")
  POLICY_ARN=$(echo "$CREATE_OUT" | jq -r '.Policy.Arn')
  echo "Created policy: $POLICY_ARN"
else
  POLICY_ARN=$EXISTING_ARN
  echo "Policy already exists: $POLICY_ARN"
fi

echo "Attaching policy ${POLICY_ARN} to role ${ROLE_NAME}..."
aws iam attach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${POLICY_ARN}"

echo "Policy attached."

# Helpful output
echo "If you used an instance profile, the EC2 instance may need a few minutes to pick up new permissions."
