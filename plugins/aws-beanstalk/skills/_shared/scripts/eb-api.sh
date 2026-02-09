#!/usr/bin/env bash
# EB CLI helper with error handling
# Usage: eb-api.sh <command> [args...]

set -e

# Check if EB CLI is installed
if ! command -v eb &>/dev/null; then
  echo "ERROR: EB CLI not installed."
  echo "Install with: pip install awsebcli"
  echo "Or: brew install awsebcli"
  exit 1
fi

# Check if command provided
if [[ -z "$1" ]]; then
  echo "ERROR: No command provided."
  echo "Usage: eb-api.sh <command> [args...]"
  exit 1
fi

# Execute EB CLI command
COMMAND="$1"
shift

# Run the command and capture output
OUTPUT=$(eb "$COMMAND" "$@" 2>&1) || EXIT_CODE=$?
EXIT_CODE=${EXIT_CODE:-0}

if [[ $EXIT_CODE -ne 0 ]]; then
  # Classify common EB CLI errors
  if echo "$OUTPUT" | grep -qi "not initialized\|This directory has not been set up"; then
    echo "ERROR: Project not initialized. Run: eb init"
  elif echo "$OUTPUT" | grep -qi "No Environment found\|No environment"; then
    echo "ERROR: No environment found. Run: eb list"
  elif echo "$OUTPUT" | grep -qi "credentials\|Unable to locate\|InvalidClientTokenId"; then
    echo "ERROR: AWS credentials not configured. Run: aws configure"
  elif echo "$OUTPUT" | grep -qi "ServiceError\|ServiceException"; then
    echo "ERROR: AWS service error."
    echo "$OUTPUT"
  else
    echo "ERROR: Command failed (exit code $EXIT_CODE)"
    echo "$OUTPUT"
  fi
  exit $EXIT_CODE
fi

echo "$OUTPUT"
