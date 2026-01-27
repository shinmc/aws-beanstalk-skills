---
name: status
description: This skill should be used when the user asks "eb status", "environment status", "what's running", "is it deployed", or about current deployment state. NOT for logs (use logs skill), NOT for detailed health metrics (use health skill).
argument-hint: "[env-name]"
allowed-tools: Bash(aws elasticbeanstalk:*), Bash(scripts/eb-api.sh:*)
---

# AWS Elastic Beanstalk Status

Check the current status of Elastic Beanstalk environments and applications.

## When to Use

- User asks about environment status, deployment state
- User says "is my app running", "what's deployed", "environment info"
- Before any deployment operation (to verify current state)
- User asks about available environments or applications

## When NOT to Use

- For detailed logs → use `logs` skill
- For instance-level health → use `health` skill
- For configuration details → use `config` skill
- For deployment history → use `logs` skill with events

## Region Handling

Commands use your default AWS region (`AWS_DEFAULT_REGION` or `~/.aws/config`).

**Check current region:**
```bash
aws configure get region
```

**Override for specific commands:**
```bash
aws elasticbeanstalk describe-environments --region us-west-2
```

**For multi-region setups:** Always specify `--region` explicitly to avoid targeting the wrong environment.

## Quick Status Check

Get environment status:
```bash
aws elasticbeanstalk describe-environments \
  --environment-names <env-name> \
  --output json
```

List all environments for an application:
```bash
aws elasticbeanstalk describe-environments \
  --application-name <app-name> \
  --output json
```

List all applications:
```bash
aws elasticbeanstalk describe-applications --output json
```

## Get Environment Resources

View instances, load balancers, and other resources:
```bash
aws elasticbeanstalk describe-environment-resources \
  --environment-name <env-name> \
  --output json
```

## Response Fields

Key fields from `describe-environments`:
- `EnvironmentName` - Environment name
- `Status` - Launching, Updating, Ready, Terminating, Terminated
- `Health` - Green, Yellow, Red, Grey
- `HealthStatus` - Ok, Warning, Degraded, Severe, Info, Pending, Unknown
- `VersionLabel` - Currently deployed version
- `SolutionStackName` - Platform (Node.js, Python, etc.)
- `CNAME` - Environment URL
- `DateUpdated` - Last update timestamp

## Presenting Status

Parse JSON and present:
- **Application**: name
- **Environment**: name and status
- **Health**: color and status
- **Version**: currently deployed version
- **URL**: environment CNAME
- **Platform**: solution stack

Example output:
```
Application: my-app
Environment: my-app-prod (Ready)
Health: Green (Ok)
Version: v1.2.3
URL: my-app-prod.elasticbeanstalk.com
Platform: 64bit Amazon Linux 2023 v6.7.2 running Node.js 20
```

## Check Specific Application

```bash
aws elasticbeanstalk describe-applications \
  --application-names <app-name> \
  --output json
```

## Error Handling

### AWS CLI Not Installed
```
AWS CLI is not installed. Install with:
- macOS: brew install awscli
- pip: pip install awscli
Then configure: aws configure
```

### Not Authenticated
```
AWS credentials not configured. Run:
aws configure
```

### Environment Not Found
```
Environment "<name>" not found. List available environments:
aws elasticbeanstalk describe-environments
```

### No Environments
```
No environments found for application "<name>".
Create one with: aws elasticbeanstalk create-environment
```

## Common Workflows

### Deploy and Verify
1. `status` → Check current state before deployment
2. `deploy` → Push new version
3. `status` → Verify deployment started
4. `logs` → Watch for errors during deployment
5. `health` → Confirm healthy state after deployment

### Investigate Issues
1. `status` → Check environment status and health color
2. `health` → Get detailed health metrics
3. `logs` → Retrieve application and error logs
4. `troubleshoot` → Get comprehensive diagnosis and recommendations

### Scale Environment
1. `status` → Check current instance count
2. `health` → Verify current load/utilization
3. `config` → Update scaling settings (MinSize, MaxSize)
4. `status` → Confirm scaling in progress

### Blue/Green Deployment
1. `status` → Check current environment state
2. `environment` → Create new environment with new version
3. `status` → Wait for new environment to be Ready
4. `health` → Verify new environment is healthy
5. `environment` → Swap CNAMEs
6. `environment` → Terminate old environment (optional)

## Composability

- **View logs**: Use `logs` skill
- **Check detailed health**: Use `health` skill
- **Deploy new version**: Use `deploy` skill
- **Modify configuration**: Use `config` skill

## Additional Resources

For detailed reference information, see the shared reference files:

- [Configuration Options](../_shared/references/config-options.md) - All available configuration namespaces and options
- [Health States](../_shared/references/health-states.md) - Health colors, statuses, and thresholds
- [Cost Optimization](../_shared/references/cost-optimization.md) - Instance sizing, scaling, and cost-saving strategies
- [Platforms](../_shared/references/platforms.md) - Platform-specific configuration and requirements
