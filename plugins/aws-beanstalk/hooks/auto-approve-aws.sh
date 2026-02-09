#!/bin/bash
# Auto-approve AWS Elastic Beanstalk plugin commands

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

# Auto-approve eb CLI commands (EB CLI)
if [[ "$command" =~ ^eb[[:space:]] ]] || [[ "$command" == "eb" ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "EB CLI command auto-approved"
  }
}
EOF
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

# Auto-approve aws elasticbeanstalk commands (fallback for some operations)
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

# Auto-approve aws iam commands for EB role management (get-role, get-instance-profile, create-role, attach-role-policy, create-instance-profile, add-role-to-instance-profile)
if [[ "$command" =~ ^aws[[:space:]]+iam[[:space:]]+(get-role|get-instance-profile|create-role|attach-role-policy|create-instance-profile|add-role-to-instance-profile)[[:space:]] ]]; then
  # Only auto-approve if related to elasticbeanstalk roles
  if [[ "$command" == *"elasticbeanstalk"* ]]; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS IAM command auto-approved for EB role management"
  }
}
EOF
    exit 0
  fi
fi

# Auto-approve aws ec2 describe commands (for troubleshooting and security audit)
if [[ "$command" =~ ^aws[[:space:]]+ec2[[:space:]]+(describe-instance-status|describe-instances|describe-security-groups)[[:space:]] ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS EC2 describe command auto-approved for EB troubleshooting"
  }
}
EOF
  exit 0
fi

# Auto-approve aws elbv2 describe commands (for load balancer health checks)
if [[ "$command" =~ ^aws[[:space:]]+elbv2[[:space:]]+(describe-target-health|describe-target-groups|describe-load-balancers)[[:space:]] ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS ELBv2 describe command auto-approved for EB troubleshooting"
  }
}
EOF
  exit 0
fi

# Auto-approve aws autoscaling describe commands (for ASG inspection)
if [[ "$command" =~ ^aws[[:space:]]+autoscaling[[:space:]]+(describe-scaling-activities|describe-auto-scaling-groups)[[:space:]] ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS AutoScaling describe command auto-approved for EB troubleshooting"
  }
}
EOF
  exit 0
fi

# Auto-approve aws acm commands (for SSL certificate management)
if [[ "$command" =~ ^aws[[:space:]]+acm[[:space:]]+(list-certificates|describe-certificate|request-certificate|delete-certificate)[[:space:]] ]] || [[ "$command" =~ ^aws[[:space:]]+acm[[:space:]]+(list-certificates|describe-certificate)$ ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS ACM command auto-approved for EB SSL management"
  }
}
EOF
  exit 0
fi

# Auto-approve aws route53 commands (for custom domain management)
if [[ "$command" =~ ^aws[[:space:]]+route53[[:space:]]+(list-hosted-zones|list-resource-record-sets|change-resource-record-sets|get-change)[[:space:]] ]] || [[ "$command" =~ ^aws[[:space:]]+route53[[:space:]]+list-hosted-zones$ ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS Route 53 command auto-approved for EB domain management"
  }
}
EOF
  exit 0
fi

# Auto-approve aws secretsmanager commands (for secrets management)
if [[ "$command" =~ ^aws[[:space:]]+secretsmanager[[:space:]] ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS Secrets Manager command auto-approved for EB secrets management"
  }
}
EOF
  exit 0
fi

# Auto-approve aws ssm commands (for SSM Parameter Store)
if [[ "$command" =~ ^aws[[:space:]]+ssm[[:space:]]+(get-parameter|get-parameters-by-path|put-parameter|delete-parameter|describe-parameters)[[:space:]] ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS SSM command auto-approved for EB parameter management"
  }
}
EOF
  exit 0
fi

# Auto-approve aws rds describe/snapshot commands (for database monitoring)
if [[ "$command" =~ ^aws[[:space:]]+rds[[:space:]]+(describe-db-instances|describe-db-snapshots|create-db-snapshot|describe-pending-maintenance-actions|download-db-log-file-portion)[[:space:]] ]] || [[ "$command" =~ ^aws[[:space:]]+rds[[:space:]]+describe-db-instances$ ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS RDS command auto-approved for EB database monitoring"
  }
}
EOF
  exit 0
fi

# Auto-approve aws ce commands (for cost analysis)
if [[ "$command" =~ ^aws[[:space:]]+ce[[:space:]]+(get-cost-and-usage|get-cost-forecast|get-tags)[[:space:]] ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS Cost Explorer command auto-approved for EB cost analysis"
  }
}
EOF
  exit 0
fi

# Auto-approve aws sns commands (for monitoring alarm notifications)
if [[ "$command" =~ ^aws[[:space:]]+sns[[:space:]]+(create-topic|subscribe|list-topics|list-subscriptions)[[:space:]] ]] || [[ "$command" =~ ^aws[[:space:]]+sns[[:space:]]+list-topics$ ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "AWS SNS command auto-approved for EB monitoring"
  }
}
EOF
  exit 0
fi

exit 0
