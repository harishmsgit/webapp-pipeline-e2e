#!/usr/bin/env bash
set -euo pipefail

JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_TOKEN="${JENKINS_TOKEN:-11bfdb70fca3fce33dc2df4f944c008bf6}" 
JOB_NAME="${JOB_NAME:-seed-job}"
CONFIG_XML="${CONFIG_XML:-ci/jenkins/seed-job-config.xml}"

if [[ -z "$JENKINS_TOKEN" ]]; then
  echo "Set JENKINS_TOKEN to your Jenkins API token or use a basic auth user:token." >&2
  echo "Example:" >&2
  echo "  JENKINS_URL=http://localhost:8080 JENKINS_USER=admin JENKINS_TOKEN=JENKINS_TOKEN JOB_NAME=seed-job bash ci/jenkins/create_seed_job.sh" >&2
  exit 1
fi

if [[ ! -f "$CONFIG_XML" ]]; then
  echo "Config file not found: $CONFIG_XML" >&2
  exit 1
fi

curl -sS -X POST \
  -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -H "Content-Type: application/xml" \
  --data-binary @"$CONFIG_XML" \
  "$JENKINS_URL/createItem?name=$JOB_NAME"

echo
