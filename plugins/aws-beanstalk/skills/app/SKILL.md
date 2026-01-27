---
name: app
description: This skill should be used when the user wants to create, delete, or manage Elastic Beanstalk applications, "create beanstalk app", "new eb application", "list applications", "my beanstalk apps", configure resource lifecycle, or manage application versions. For environments, use environment skill.
argument-hint: "[app-name]"
disable-model-invocation: true
allowed-tools: Bash(aws elasticbeanstalk:*), Bash(scripts/eb-api.sh:*)
---

# AWS Elastic Beanstalk Application Management

Create, manage, and configure Elastic Beanstalk applications and their lifecycle.

## When to Use

- User wants to create a new application
- User says "delete application", "remove app"
- User asks about application lifecycle settings
- User wants to manage application versions
- User asks "list my applications"

## When NOT to Use

- For environment operations → use `environment` skill
- For deploying → use `deploy` skill
- For configuration → use `config` skill

## Destructive Operations Warning

**Before deleting applications or versions:**

1. **Verify the application name** - Double-check you're targeting the correct application
2. **Check for running environments** - Deletion with `--terminate-env-by-force` destroys ALL environments
3. **Confirm with user** - Always ask for explicit confirmation before destructive actions
4. **Consider version dependencies** - Versions in use cannot be deleted

Commands requiring extra caution:
- `delete-application` - Deletes app and ALL versions
- `delete-application --terminate-env-by-force` - Also terminates ALL environments
- `delete-application-version --delete-source-bundle` - Permanently removes S3 artifacts

## List Applications

```bash
aws elasticbeanstalk describe-applications \
  --output json
```

Specific application:
```bash
aws elasticbeanstalk describe-applications \
  --application-names <app-name> \
  --output json
```

## Create Application

```bash
aws elasticbeanstalk create-application \
  --application-name <app-name> \
  --description "My application description" \
  --output json
```

### With Resource Lifecycle
```bash
aws elasticbeanstalk create-application \
  --application-name <app-name> \
  --description "My application" \
  --resource-lifecycle-config '{
    "ServiceRole": "arn:aws:iam::<account>:role/aws-elasticbeanstalk-service-role",
    "VersionLifecycleConfig": {
      "MaxCountRule": {
        "Enabled": true,
        "MaxCount": 50,
        "DeleteSourceFromS3": false
      }
    }
  }' \
  --output json
```

## Update Application

```bash
aws elasticbeanstalk update-application \
  --application-name <app-name> \
  --description "Updated description" \
  --output json
```

## Delete Application

**Warning:** This deletes all environments and versions!

```bash
aws elasticbeanstalk delete-application \
  --application-name <app-name> \
  --output json
```

Force delete (terminates running environments):
```bash
aws elasticbeanstalk delete-application \
  --application-name <app-name> \
  --terminate-env-by-force \
  --output json
```

## Application Versions

### List Versions
```bash
aws elasticbeanstalk describe-application-versions \
  --application-name <app-name> \
  --max-records 20 \
  --output json
```

### Delete Version
```bash
aws elasticbeanstalk delete-application-version \
  --application-name <app-name> \
  --version-label "v1.0.0" \
  --output json
```

Delete and remove source from S3:
```bash
aws elasticbeanstalk delete-application-version \
  --application-name <app-name> \
  --version-label "v1.0.0" \
  --delete-source-bundle \
  --output json
```

### Update Version Metadata
```bash
aws elasticbeanstalk update-application-version \
  --application-name <app-name> \
  --version-label "v1.0.0" \
  --description "Updated description" \
  --output json
```

## Resource Lifecycle Configuration

Control automatic cleanup of old versions:

### Get Current Settings
```bash
aws elasticbeanstalk describe-application-versions \
  --application-name <app-name> \
  --output json | jq '.ApplicationVersions | length'
```

### Configure Lifecycle
```bash
aws elasticbeanstalk update-application-resource-lifecycle \
  --application-name <app-name> \
  --resource-lifecycle-config '{
    "ServiceRole": "arn:aws:iam::<account>:role/aws-elasticbeanstalk-service-role",
    "VersionLifecycleConfig": {
      "MaxCountRule": {
        "Enabled": true,
        "MaxCount": 50,
        "DeleteSourceFromS3": true
      },
      "MaxAgeRule": {
        "Enabled": true,
        "MaxAgeInDays": 90,
        "DeleteSourceFromS3": true
      }
    }
  }' \
  --output json
```

### Lifecycle Options

**MaxCountRule:** Keep only N most recent versions
- `MaxCount`: Number of versions to retain
- `DeleteSourceFromS3`: Also delete source bundles

**MaxAgeRule:** Delete versions older than N days
- `MaxAgeInDays`: Maximum age in days
- `DeleteSourceFromS3`: Also delete source bundles

## Application Tags

### List Tags
```bash
aws elasticbeanstalk list-tags-for-resource \
  --resource-arn arn:aws:elasticbeanstalk:<region>:<account>:application/<app-name> \
  --output json
```

### Add Tags
```bash
aws elasticbeanstalk update-tags-for-resource \
  --resource-arn arn:aws:elasticbeanstalk:<region>:<account>:application/<app-name> \
  --tags-to-add Key=Team,Value=backend Key=Project,Value=api \
  --output json
```

### Remove Tags
```bash
aws elasticbeanstalk update-tags-for-resource \
  --resource-arn arn:aws:elasticbeanstalk:<region>:<account>:application/<app-name> \
  --tags-to-remove Team Project \
  --output json
```

## Account Attributes

Check account-level settings:
```bash
aws elasticbeanstalk describe-account-attributes \
  --output json
```

Shows:
- `Applications`: Max and current count
- `Environments`: Max and current count
- `ConfigurationTemplates`: Max and current count

## Presenting Application Info

Example output:
```
=== Application: my-app ===

Created: 2024-01-01 10:00:00
Description: My web application

Environments:
  - my-app-prod (Ready, Green)
  - my-app-staging (Ready, Green)
  - my-app-dev (Ready, Yellow)

Versions: 25 total
  Latest: v1.2.3 (deployed to prod)

Lifecycle Rules:
  - Keep max 50 versions
  - Delete versions older than 90 days
  - Source bundles deleted on cleanup
```

## Error Handling

### Application Already Exists
```
Application already exists. Use a different name or update the existing application:
aws elasticbeanstalk update-application --application-name <name> --description "..."
```

### Application Has Running Environments
```
Cannot delete application with running environments.
Terminate environments first or use --terminate-env-by-force
```

### Version In Use
```
Cannot delete version currently deployed to an environment.
Deploy a different version first:
aws elasticbeanstalk update-environment --environment-name <env> --version-label <other-version>
```

### Lifecycle Role Missing
```
Service role required for lifecycle management.
Create role with Elastic Beanstalk permissions or use:
arn:aws:iam::<account>:role/aws-elasticbeanstalk-service-role
```

## Composability

- **Create environments**: Use `environment` skill
- **Deploy versions**: Use `deploy` skill
- **Check environment status**: Use `status` skill

## Additional Resources

For detailed reference information, see the shared reference files:

- [Configuration Options](../_shared/references/config-options.md) - All available configuration namespaces and options
- [Health States](../_shared/references/health-states.md) - Health colors, statuses, and thresholds
- [Cost Optimization](../_shared/references/cost-optimization.md) - Instance sizing, scaling, and cost-saving strategies
- [Platforms](../_shared/references/platforms.md) - Platform-specific configuration and requirements
