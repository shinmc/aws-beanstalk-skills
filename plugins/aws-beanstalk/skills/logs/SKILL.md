---
name: logs
description: This skill should be used when the user asks for logs, events, "show me the logs", "what happened", "check errors", "deployment events", "beanstalk logs", "eb logs", "view logs", "get logs", or needs to debug issues. Covers both application logs and environment events.
argument-hint: "[env-name]"
allowed-tools: Bash(aws elasticbeanstalk:*), Bash(curl:*), Bash(scripts/eb-api.sh:*)
---

# AWS Elastic Beanstalk Logs

Request, retrieve, and analyze logs from Elastic Beanstalk environments.

## When to Use

- User asks "show logs", "check errors", "what's happening"
- User wants to debug application issues
- User asks about recent events or deployment history
- User says "why did it fail", "check the logs"

## When NOT to Use

- For environment status → use `status` skill
- For instance health metrics → use `health` skill
- For configuration issues → use `config` skill
- For comprehensive "why is it failing" diagnosis → use `troubleshoot` skill (it combines logs + health + config)

## Log Types

### Tail Logs (Last 100 lines)
Quick snapshot of recent logs from all instances:
```bash
aws elasticbeanstalk request-environment-info \
  --environment-name <env-name> \
  --info-type tail \
  --output json
```

### Bundle Logs (Full logs)
Complete log bundle (includes more log files):
```bash
aws elasticbeanstalk request-environment-info \
  --environment-name <env-name> \
  --info-type bundle \
  --output json
```

## Retrieve Logs

After requesting, retrieve the logs (wait 30-60 seconds for bundle):
```bash
aws elasticbeanstalk retrieve-environment-info \
  --environment-name <env-name> \
  --info-type tail \
  --output json
```

Response contains S3 presigned URLs:
```json
{
  "EnvironmentInfo": [
    {
      "InfoType": "tail",
      "Ec2InstanceId": "i-1234567890abcdef0",
      "SampleTimestamp": "2024-01-15T10:30:00Z",
      "Message": "https://s3.amazonaws.com/..."
    }
  ]
}
```

### Download and View Logs

```bash
# Get log URLs
URLS=$(aws elasticbeanstalk retrieve-environment-info \
  --environment-name <env-name> \
  --info-type tail \
  --query 'EnvironmentInfo[].Message' \
  --output text)

# Download and display
for URL in $URLS; do
  curl -s "$URL"
done
```

## Environment Events

View recent events (deployments, config changes, errors):
```bash
aws elasticbeanstalk describe-events \
  --environment-name <env-name> \
  --max-records 20 \
  --output json
```

### Filter Events by Severity
```bash
# Only errors and warnings
aws elasticbeanstalk describe-events \
  --environment-name <env-name> \
  --severity ERROR \
  --output json

aws elasticbeanstalk describe-events \
  --environment-name <env-name> \
  --severity WARN \
  --output json
```

### Filter Events by Time
```bash
# Events since specific time
aws elasticbeanstalk describe-events \
  --environment-name <env-name> \
  --start-time 2024-01-15T00:00:00Z \
  --output json
```

## Common Log Locations

Logs include files from:
- `/var/log/web.stdout.log` - Application stdout
- `/var/log/web.stderr.log` - Application stderr
- `/var/log/eb-engine.log` - EB platform logs
- `/var/log/nginx/access.log` - Web server access
- `/var/log/nginx/error.log` - Web server errors

## Interpreting Logs

### Common Error Patterns

**Node.js**
```
Error: Cannot find module 'express'
→ Fix: Ensure package.json includes all dependencies
```

**Python**
```
ModuleNotFoundError: No module named 'flask'
→ Fix: Check requirements.txt includes all packages
```

**Docker**
```
Error response from daemon: pull access denied
→ Fix: Check Docker Hub credentials or ECR permissions
```

**Java**
```
java.lang.OutOfMemoryError: Java heap space
→ Fix: Increase instance size or adjust JVM heap settings
```

## Log Workflow

### Full Debug Flow
```bash
# 1. Request logs
aws elasticbeanstalk request-environment-info \
  --environment-name <env-name> \
  --info-type tail

# 2. Wait a moment, then retrieve
sleep 10

# 3. Get URLs and download
aws elasticbeanstalk retrieve-environment-info \
  --environment-name <env-name> \
  --info-type tail \
  --query 'EnvironmentInfo[].Message' \
  --output text | xargs -I {} curl -s {}
```

### Quick Event Check
```bash
aws elasticbeanstalk describe-events \
  --environment-name <env-name> \
  --severity ERROR \
  --max-records 5 \
  --query 'Events[].{Time:EventDate,Msg:Message}' \
  --output table
```

## Presenting Logs

When showing logs:
- Highlight ERROR and WARN lines
- Show timestamps
- Summarize error patterns
- Suggest fixes for common issues

Example output:
```
=== Recent Errors (my-app-prod) ===

[2024-01-15 10:30:15] ERROR: Connection refused to database
[2024-01-15 10:30:16] ERROR: Health check failed - 503 response
[2024-01-15 10:30:20] WARN: High memory usage (85%)

Suggestion: Database connection issue detected. Check:
1. RDS security group allows inbound from EB instances
2. DATABASE_URL environment variable is correct
3. Database is running and accepting connections
```

## Error Handling

### No Logs Available
```
No logs available. Logs may not be ready yet. Wait 30-60 seconds and try again:
aws elasticbeanstalk retrieve-environment-info --environment-name <env> --info-type tail
```

### Log Retrieval Timeout
```
Log URLs expire after a few minutes. Request fresh logs:
aws elasticbeanstalk request-environment-info --environment-name <env> --info-type tail
```

### Environment Not Found
```
Environment not found. List available environments:
aws elasticbeanstalk describe-environments
```

## Composability

- **Check environment health**: Use `health` skill
- **Fix configuration**: Use `config` skill
- **Diagnose issues**: Use `troubleshoot` skill
- **Redeploy**: Use `deploy` skill

## Additional Resources

For detailed reference information, see the shared reference files:

- [Configuration Options](../_shared/references/config-options.md) - All available configuration namespaces and options
- [Health States](../_shared/references/health-states.md) - Health colors, statuses, and thresholds
- [Cost Optimization](../_shared/references/cost-optimization.md) - Instance sizing, scaling, and cost-saving strategies
- [Platforms](../_shared/references/platforms.md) - Platform-specific configuration and requirements
