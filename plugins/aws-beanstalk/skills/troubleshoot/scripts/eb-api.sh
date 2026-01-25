#!/usr/bin/env bash
# AWS Elastic Beanstalk CLI helper with error handling and JSON output
# Usage: eb-api.sh <command> [args...]

set -e

# Check if AWS CLI is installed
if ! command -v aws &>/dev/null; then
  echo '{"error": "AWS CLI not installed. Install with: brew install awscli or pip install awscli"}'
  exit 1
fi

# Check if jq is installed (for JSON parsing)
if ! command -v jq &>/dev/null; then
  echo '{"error": "jq not installed. Install with: brew install jq"}'
  exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &>/dev/null 2>&1; then
  echo '{"error": "AWS credentials not configured or expired. Run: aws configure"}'
  exit 1
fi

# Check if command provided
if [[ -z "$1" ]]; then
  echo '{"error": "No command provided. Usage: eb-api.sh <command> [args...]"}'
  exit 1
fi

# Execute AWS Elastic Beanstalk command with JSON output
COMMAND="$1"
shift

# Build the full command
RESULT=$(aws elasticbeanstalk "$COMMAND" --output json "$@" 2>&1)
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
  # Parse common AWS CLI errors
  if echo "$RESULT" | grep -q "AccessDenied"; then
    echo "{\"error\": \"Access denied. Check IAM permissions for elasticbeanstalk:$COMMAND\", \"details\": $(echo "$RESULT" | jq -Rs .)}"
  elif echo "$RESULT" | grep -q "ResourceNotFoundException"; then
    echo "{\"error\": \"Resource not found\", \"details\": $(echo "$RESULT" | jq -Rs .)}"
  elif echo "$RESULT" | grep -q "InvalidParameterValue"; then
    echo "{\"error\": \"Invalid parameter value\", \"details\": $(echo "$RESULT" | jq -Rs .)}"
  elif echo "$RESULT" | grep -q "ValidationError"; then
    echo "{\"error\": \"Validation error\", \"details\": $(echo "$RESULT" | jq -Rs .)}"
  else
    echo "{\"error\": \"Command failed\", \"details\": $(echo "$RESULT" | jq -Rs .)}"
  fi
  exit 1
fi

echo "$RESULT"
