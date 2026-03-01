#!/bin/bash
# Auto-approve AWS Elastic Beanstalk plugin commands

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

# ── Helper: emit approval JSON ──
approve() {
  local reason="$1"
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "$reason"
  }
}
EOF
  exit 0
}

# ── Reject chained commands to prevent bypass (e.g. "eb status && rm -rf /") ──
if [[ "$command" == *"&&"* ]] || [[ "$command" == *"||"* ]] || [[ "$command" == *";"* ]]; then
  exit 0  # Require manual approval for chained commands
fi

# ── Reject command substitution to prevent embedded execution ──
if [[ "$command" == *'$('* ]] || [[ "$command" == *'`'* ]]; then
  exit 0  # Require manual approval for command substitution
fi

# ── Validate piped commands — ALL pipe targets must be safe ──
# NOTE: awk and sed are excluded because they can execute arbitrary commands
# (awk via system(), sed via the 'e' flag on GNU sed)
if [[ "$command" == *"|"* ]]; then
  IFS='|' read -ra PIPE_PARTS <<< "$command"
  for part in "${PIPE_PARTS[@]:1}"; do
    trimmed=$(echo "$part" | xargs)
    cmd_name=$(echo "$trimmed" | cut -d' ' -f1)
    if ! [[ "$cmd_name" =~ ^(jq|grep|head|tail|sort|wc|less|cat|tee|tr|cut|column|uniq|nl|fmt|paste)$ ]]; then
      exit 0  # Unsafe pipe target, require manual approval
    fi
  done
fi

# ── Deny destructive commands (require manual user confirmation) ──

# EB CLI destructive commands
if [[ "$command" =~ ^eb[[:space:]]+terminate ]] || \
   [[ "$command" =~ ^eb[[:space:]]+appversion[[:space:]]+--delete ]]; then
  exit 0
fi

# AWS S3 destructive commands (rm, rb, mv)
if [[ "$command" =~ ^aws[[:space:]]+s3[[:space:]]+(rm|rb|mv)[[:space:]] ]]; then
  exit 0
fi

# AWS S3 sync with --delete flag (removes files at destination)
if [[ "$command" =~ ^aws[[:space:]]+s3[[:space:]]+sync[[:space:]] ]] && [[ "$command" == *"--delete"* ]]; then
  exit 0
fi

# AWS ElasticBeanstalk destructive API calls
if [[ "$command" =~ ^aws[[:space:]]+elasticbeanstalk[[:space:]]+(terminate-environment|delete-application|delete-application-version|delete-environment-configuration|delete-platform-version)[[:space:]] ]]; then
  exit 0
fi

# AWS Secrets Manager destructive commands
if [[ "$command" =~ ^aws[[:space:]]+secretsmanager[[:space:]]+(delete-secret|delete-resource-policy)[[:space:]] ]]; then
  exit 0
fi

# AWS SSM destructive commands
if [[ "$command" =~ ^aws[[:space:]]+ssm[[:space:]]+delete-parameter[[:space:]] ]] || \
   [[ "$command" =~ ^aws[[:space:]]+ssm[[:space:]]+delete-parameters[[:space:]] ]]; then
  exit 0
fi

# AWS ACM destructive commands
if [[ "$command" =~ ^aws[[:space:]]+acm[[:space:]]+delete-certificate[[:space:]] ]]; then
  exit 0
fi

# AWS CloudWatch destructive/write commands
if [[ "$command" =~ ^aws[[:space:]]+cloudwatch[[:space:]]+(delete-alarms|put-metric-alarm)[[:space:]] ]]; then
  exit 0
fi

# AWS Route 53 DELETE actions (record deletion) — case-insensitive match
if [[ "$command" =~ ^aws[[:space:]]+route53[[:space:]]+change-resource-record-sets ]]; then
  if echo "$command" | grep -qi '"Action"[[:space:]]*:[[:space:]]*"DELETE"'; then
    exit 0
  fi
fi

# ── Auto-approve safe commands below ──

# Auto-approve eb CLI commands (EB CLI)
if [[ "$command" =~ ^eb[[:space:]] ]] || [[ "$command" == "eb" ]]; then
  approve "EB CLI command auto-approved"
fi

# Auto-approve aws elasticbeanstalk commands
if [[ "$command" =~ ^aws[[:space:]]+elasticbeanstalk[[:space:]] ]]; then
  approve "AWS Elastic Beanstalk CLI command auto-approved"
fi

# Auto-approve aws s3 commands (for deployment artifacts)
if [[ "$command" =~ ^aws[[:space:]]+s3[[:space:]] ]]; then
  approve "AWS S3 command auto-approved for EB deployments"
fi

# Auto-approve aws cloudwatch read-only commands (for metrics/troubleshooting)
if [[ "$command" =~ ^aws[[:space:]]+cloudwatch[[:space:]]+(get-metric-statistics|list-metrics|describe-alarms)[[:space:]] ]]; then
  approve "AWS CloudWatch command auto-approved for EB monitoring"
fi

# Auto-approve curl for fetching EB log URLs (presigned S3 URLs)
# Matches curl with any combination of flags (e.g. -s, -sS, -fsSL)
if [[ "$command" =~ ^curl[[:space:]]+-[a-zA-Z]*s ]] && [[ "$command" == *"s3"* || "$command" == *"amazonaws.com"* ]]; then
  approve "Curl command auto-approved for fetching EB logs"
fi

# Auto-approve aws iam commands for EB role management
if [[ "$command" =~ ^aws[[:space:]]+iam[[:space:]]+(get-role|get-instance-profile|list-attached-role-policies)[[:space:]] ]]; then
  # Only auto-approve if related to elasticbeanstalk roles
  if [[ "$command" == *"elasticbeanstalk"* ]]; then
    approve "AWS IAM command auto-approved for EB role management"
  fi
fi

# Auto-approve aws ec2 describe commands (for troubleshooting and security audit)
if [[ "$command" =~ ^aws[[:space:]]+ec2[[:space:]]+(describe-instance-status|describe-instances|describe-security-groups)[[:space:]] ]]; then
  approve "AWS EC2 describe command auto-approved for EB troubleshooting"
fi

# Auto-approve aws elbv2 describe commands (for load balancer health checks)
if [[ "$command" =~ ^aws[[:space:]]+elbv2[[:space:]]+(describe-target-health|describe-target-groups|describe-load-balancers)[[:space:]] ]]; then
  approve "AWS ELBv2 describe command auto-approved for EB troubleshooting"
fi

# Auto-approve aws autoscaling describe commands (for ASG inspection)
if [[ "$command" =~ ^aws[[:space:]]+autoscaling[[:space:]]+(describe-scaling-activities|describe-auto-scaling-groups)[[:space:]] ]]; then
  approve "AWS AutoScaling describe command auto-approved for EB troubleshooting"
fi

# Auto-approve aws acm commands (for SSL certificate management)
if [[ "$command" =~ ^aws[[:space:]]+acm[[:space:]]+(list-certificates|describe-certificate|request-certificate)[[:space:]] ]] || \
   [[ "$command" =~ ^aws[[:space:]]+acm[[:space:]]+(list-certificates|describe-certificate)$ ]]; then
  approve "AWS ACM command auto-approved for EB SSL management"
fi

# Auto-approve aws route53 commands (for custom domain management)
if [[ "$command" =~ ^aws[[:space:]]+route53[[:space:]]+(list-hosted-zones|list-resource-record-sets|change-resource-record-sets|get-change)[[:space:]] ]] || \
   [[ "$command" =~ ^aws[[:space:]]+route53[[:space:]]+list-hosted-zones$ ]]; then
  approve "AWS Route 53 command auto-approved for EB domain management"
fi

# Auto-approve aws secretsmanager commands (explicit allowlist)
if [[ "$command" =~ ^aws[[:space:]]+secretsmanager[[:space:]]+(create-secret|get-secret-value|list-secrets|describe-secret|update-secret|rotate-secret)[[:space:]] ]] || \
   [[ "$command" =~ ^aws[[:space:]]+secretsmanager[[:space:]]+list-secrets$ ]]; then
  approve "AWS Secrets Manager command auto-approved for EB secrets management"
fi

# Auto-approve aws ssm commands (for SSM Parameter Store)
if [[ "$command" =~ ^aws[[:space:]]+ssm[[:space:]]+(get-parameter|get-parameters-by-path|put-parameter|describe-parameters)[[:space:]] ]]; then
  approve "AWS SSM command auto-approved for EB parameter management"
fi

# Auto-approve aws rds describe/snapshot commands (for database monitoring)
if [[ "$command" =~ ^aws[[:space:]]+rds[[:space:]]+(describe-db-instances|describe-db-snapshots|create-db-snapshot|describe-pending-maintenance-actions|download-db-log-file-portion)[[:space:]] ]] || \
   [[ "$command" =~ ^aws[[:space:]]+rds[[:space:]]+describe-db-instances$ ]]; then
  approve "AWS RDS command auto-approved for EB database monitoring"
fi

# Auto-approve aws ce commands (for cost analysis)
if [[ "$command" =~ ^aws[[:space:]]+ce[[:space:]]+(get-cost-and-usage|get-cost-forecast|get-tags)[[:space:]] ]]; then
  approve "AWS Cost Explorer command auto-approved for EB cost analysis"
fi

# Auto-approve aws sns commands (for monitoring alarm notifications)
if [[ "$command" =~ ^aws[[:space:]]+sns[[:space:]]+(create-topic|subscribe|list-topics|list-subscriptions)[[:space:]] ]] || \
   [[ "$command" =~ ^aws[[:space:]]+sns[[:space:]]+list-topics$ ]]; then
  approve "AWS SNS command auto-approved for EB monitoring"
fi

exit 0
