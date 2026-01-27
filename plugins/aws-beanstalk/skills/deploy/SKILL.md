---
name: deploy
description: This skill should be used when the user wants to deploy code to Elastic Beanstalk, says "deploy", "push to EB", "deploy to beanstalk", "eb deploy", "create version", or "update environment". For environment creation, use environment skill.
argument-hint: "[version-label]"
disable-model-invocation: true
allowed-tools: Bash(aws elasticbeanstalk:*), Bash(aws s3:*), Bash(scripts/eb-api.sh:*)
---

# AWS Elastic Beanstalk Deploy

Deploy application versions to Elastic Beanstalk environments.

## When to Use

- User asks to "deploy", "push", "release"
- User wants to create a new application version
- User wants to update an environment to a specific version
- User says "deploy to production", "deploy v1.2.3"

## When NOT to Use

- For creating new environments → use `environment` skill
- For configuration changes without deployment → use `config` skill
- For checking deployment status → use `status` skill

## Deployment Flow

### Step 1: Package Application

For source bundles, you need a ZIP file uploaded to S3:
```bash
# Create ZIP from current directory
zip -r app-v1.2.3.zip . -x "*.git*" -x "node_modules/*"

# Upload to S3
aws s3 cp app-v1.2.3.zip s3://<bucket>/app-v1.2.3.zip
```

### Step 2: Create Application Version

```bash
aws elasticbeanstalk create-application-version \
  --application-name <app-name> \
  --version-label "v1.2.3" \
  --description "Release v1.2.3" \
  --source-bundle S3Bucket=<bucket>,S3Key=app-v1.2.3.zip \
  --output json
```

### Step 3: Deploy to Environment

```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --version-label "v1.2.3" \
  --output json
```

## Quick Deploy (Combined)

For rapid deployment, combine steps:
```bash
# Upload, create version, and deploy
VERSION="v$(date +%Y%m%d-%H%M%S)"
aws s3 cp app.zip s3://<bucket>/app-${VERSION}.zip && \
aws elasticbeanstalk create-application-version \
  --application-name <app-name> \
  --version-label "$VERSION" \
  --source-bundle S3Bucket=<bucket>,S3Key=app-${VERSION}.zip \
  --process \
  --output json && \
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --version-label "$VERSION" \
  --output json
```

## List Existing Versions

```bash
aws elasticbeanstalk describe-application-versions \
  --application-name <app-name> \
  --max-records 10 \
  --output json
```

## Rollback to Previous Version

```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --version-label "<previous-version>" \
  --output json
```

## Platform-Specific Packaging

### Node.js
```bash
# Include package.json, exclude node_modules
zip -r app.zip . -x "node_modules/*" -x ".git/*" -x "*.log"
```

### Python
```bash
# Include requirements.txt
zip -r app.zip . -x ".venv/*" -x "__pycache__/*" -x ".git/*"
```

### Java
```bash
# Deploy WAR file directly
aws elasticbeanstalk create-application-version \
  --application-name <app-name> \
  --version-label "v1.0.0" \
  --source-bundle S3Bucket=<bucket>,S3Key=app.war
```

### Docker
```bash
# Include Dockerfile and docker-compose.yml
zip -r app.zip Dockerfile docker-compose.yml app/
```

## Deployment Options

### With Environment Variables
Update environment while deploying:
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --version-label "v1.2.3" \
  --option-settings \
    Namespace=aws:elasticbeanstalk:application:environment,OptionName=NODE_ENV,Value=production
```

### Blue/Green Deployment
See `environment` skill for CNAME swap.

## Monitor Deployment

After initiating deployment:
```bash
# Check environment status
aws elasticbeanstalk describe-environments \
  --environment-names <env-name> \
  --output json

# Watch events
aws elasticbeanstalk describe-events \
  --environment-name <env-name> \
  --max-records 10 \
  --output json
```

## Presenting Deployment Results

When showing deployment status:
```
=== Deployment: my-app-prod ===

Version: v1.2.3
Status: Updating
Started: 2024-01-15 10:30:00

Progress:
  [1/4] Creating application version... Done
  [2/4] Uploading to S3... Done
  [3/4] Updating environment... In Progress
  [4/4] Health check... Pending

Monitor with:
aws elasticbeanstalk describe-events --environment-name my-app-prod
```

### On Success
```
Deployment Complete!
Version: v1.2.3
Environment: my-app-prod
Health: Green (Ok)
URL: my-app-prod.elasticbeanstalk.com
```

### On Failure
```
Deployment Failed!
Version: v1.2.3
Status: Rolled back to v1.2.2

Error: Health check failed after deployment
See logs: aws elasticbeanstalk describe-events --environment-name my-app-prod --severity ERROR
```

## Error Handling

### Version Already Exists
```
Version label already exists. Use a unique version label or delete the existing one:
aws elasticbeanstalk delete-application-version \
  --application-name <app> --version-label <version> --delete-source-bundle
```

### S3 Bucket Access Denied
```
Cannot access S3 bucket. Ensure:
1. Bucket exists and is in same region
2. IAM role has s3:GetObject permission
3. Bucket policy allows Elastic Beanstalk access
```

### Invalid Source Bundle
```
Source bundle validation failed. Check:
- ZIP file is valid
- Required files present (package.json, Dockerfile, etc.)
- File permissions are correct
```

### Environment Update In Progress
```
Environment is already updating. Wait for current update to complete:
aws elasticbeanstalk describe-environments --environment-names <env-name>
```

## Composability

- **Check status after deploy**: Use `status` skill
- **View deployment logs**: Use `logs` skill
- **Fix configuration issues**: Use `config` skill
- **Create new environment**: Use `environment` skill

## Additional Resources

For detailed reference information, see the shared reference files:

- [Configuration Options](../_shared/references/config-options.md) - All available configuration namespaces and options
- [Health States](../_shared/references/health-states.md) - Health colors, statuses, and thresholds
- [Cost Optimization](../_shared/references/cost-optimization.md) - Instance sizing, scaling, and cost-saving strategies
- [Platforms](../_shared/references/platforms.md) - Platform-specific configuration and requirements
