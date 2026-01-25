#!/bin/bash
# Auto-approve AWS Elastic Beanstalk plugin commands

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

# Auto-approve eb-api.sh calls
if [[ "$command" == *"eb-api.sh"* ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS Elastic Beanstalk API call auto-approved"
  }
}
EOF
  exit 0
fi

# Auto-approve aws elasticbeanstalk commands
if [[ "$command" =~ ^aws[[:space:]]+elasticbeanstalk[[:space:]] ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS Elastic Beanstalk CLI command auto-approved"
  }
}
EOF
  exit 0
fi

# Auto-approve aws s3 commands (for deployment artifacts)
if [[ "$command" =~ ^aws[[:space:]]+s3[[:space:]] ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS S3 command auto-approved for EB deployments"
  }
}
EOF
  exit 0
fi

# Auto-approve aws cloudwatch commands (for metrics/troubleshooting)
if [[ "$command" =~ ^aws[[:space:]]+cloudwatch[[:space:]] ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS CloudWatch command auto-approved for EB monitoring"
  }
}
EOF
  exit 0
fi

# Auto-approve curl for fetching EB log URLs (presigned S3 URLs)
if [[ "$command" =~ ^curl[[:space:]]+-s[[:space:]] ]] && [[ "$command" == *"s3"* || "$command" == *"amazonaws.com"* ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Curl command auto-approved for fetching EB logs"
  }
}
EOF
  exit 0
fi

exit 0
