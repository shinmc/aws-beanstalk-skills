---
name: maintenance
description: This skill should be used when the user asks about managed actions, platform updates, "apply patches", "restart servers", or maintenance operations. For configuration changes, use config skill.
argument-hint: "[env-name]"
disable-model-invocation: true
allowed-tools: Bash(aws elasticbeanstalk:*), Bash(scripts/eb-api.sh:*)
---

# AWS Elastic Beanstalk Maintenance

Manage platform updates, apply patches, and perform maintenance operations.

## When to Use

- User asks about pending updates or patches
- User says "apply managed action", "update platform"
- User wants to restart application servers
- User asks "what updates are available"
- User wants to see maintenance history

## When NOT to Use

- For environment configuration → use `config` skill
- For deployments → use `deploy` skill
- For health monitoring → use `health` skill

## Destructive Operations Warning

**Before running maintenance operations:**

1. **Check current traffic** - Use `health` skill to verify impact
2. **Schedule during low-traffic windows** - Prefer maintenance windows
3. **Confirm with user** - Always ask for explicit confirmation

Commands requiring extra caution:
- `rebuild-environment` - Causes downtime, recreates ALL instances
- `apply-environment-managed-action` - May cause rolling restarts
- Platform updates with `major` level - May introduce breaking changes

## View Managed Actions

### Pending Actions
```bash
aws elasticbeanstalk describe-environment-managed-actions \
  --environment-name <env-name> \
  --status Pending \
  --output json
```

### All Actions
```bash
aws elasticbeanstalk describe-environment-managed-actions \
  --environment-name <env-name> \
  --output json
```

## Managed Action Types

| Type | Description |
|------|-------------|
| `PlatformUpdate` | Update to newer platform version |
| `InstanceRefresh` | Replace instances with fresh ones |
| `Unknown` | Other maintenance actions |

## Apply Managed Action

```bash
aws elasticbeanstalk apply-environment-managed-action \
  --environment-name <env-name> \
  --action-id <action-id> \
  --output json
```

Get action ID from `describe-environment-managed-actions`.

## Managed Action History

View completed actions:
```bash
aws elasticbeanstalk describe-environment-managed-action-history \
  --environment-name <env-name> \
  --max-items 20 \
  --output json
```

## Restart App Server

Restart application without redeploying:
```bash
aws elasticbeanstalk restart-app-server \
  --environment-name <env-name> \
  --output json
```

Use when:
- Application is stuck
- Need to reload environment variables
- Clear application cache
- Restart after external resource change

**Note:** This restarts the app server (Node, Tomcat, etc.), not the EC2 instance.

## Platform Updates

### Check Current Platform
```bash
aws elasticbeanstalk describe-environments \
  --environment-names <env-name> \
  --query 'Environments[0].{Platform:SolutionStackName,PlatformArn:PlatformArn}' \
  --output json
```

### List Available Platforms
```bash
aws elasticbeanstalk list-platform-versions \
  --filters '[{"Type":"PlatformName","Operator":"contains","Values":["Node.js"]}]' \
  --output json
```

### Manual Platform Update
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --solution-stack-name "64bit Amazon Linux 2023 v6.7.2 running Node.js 20" \
  --output json
```

Or by platform ARN:
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --platform-arn "arn:aws:elasticbeanstalk:<region>::platform/Node.js 20 running on 64bit Amazon Linux 2023/6.7.2" \
  --output json
```

## Managed Updates Configuration

### Check Current Settings
```bash
aws elasticbeanstalk describe-configuration-settings \
  --application-name <app-name> \
  --environment-name <env-name> \
  --output json | jq '.ConfigurationSettings[0].OptionSettings[] | select(.Namespace == "aws:elasticbeanstalk:managedactions")'
```

### Enable Managed Updates
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:elasticbeanstalk:managedactions,OptionName=ManagedActionsEnabled,Value=true \
    Namespace=aws:elasticbeanstalk:managedactions,OptionName=PreferredStartTime,Value="Sun:10:00" \
    Namespace=aws:elasticbeanstalk:managedactions:platformupdate,OptionName=UpdateLevel,Value=minor \
  --output json
```

### Update Level Options
- `patch`: Only patch updates (safest)
- `minor`: Minor and patch updates
- `major`: All updates (use with caution)

### Maintenance Window
```bash
# Set preferred maintenance time (UTC)
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:elasticbeanstalk:managedactions,OptionName=PreferredStartTime,Value="Sun:02:00" \
  --output json
```

## Instance Replacement

Replace instances without changing configuration:
```bash
# Rebuild environment (recreates all instances)
aws elasticbeanstalk rebuild-environment \
  --environment-name <env-name> \
  --output json
```

For rolling instance replacement, update the launch configuration:
```bash
# Force instance refresh by toggling a setting
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:autoscaling:updatepolicy:rollingupdate,OptionName=RollingUpdateEnabled,Value=true \
  --output json
```

## Platform Migration (eb migrate equivalent)

Migrate an environment to a different platform version (e.g., Amazon Linux 2 to Amazon Linux 2023).

### Check Migration Compatibility

#### Step 1: Get Current Platform
```bash
aws elasticbeanstalk describe-environments \
  --environment-names <env-name> \
  --query 'Environments[0].{Platform:SolutionStackName,PlatformArn:PlatformArn}' \
  --output json
```

#### Step 2: List Compatible Platforms
```bash
# For Node.js
aws elasticbeanstalk list-platform-versions \
  --filters '[{"Type":"ProgrammingLanguageName","Operator":"=","Values":["Node.js"]}]' \
  --output json | jq '.PlatformSummaryList[] | {Name:.PlatformArn, Status:.PlatformStatus}'

# For Python
aws elasticbeanstalk list-platform-versions \
  --filters '[{"Type":"ProgrammingLanguageName","Operator":"=","Values":["Python"]}]' \
  --output json | jq '.PlatformSummaryList[] | {Name:.PlatformArn, Status:.PlatformStatus}'

# Show all supported platforms
aws elasticbeanstalk list-available-solution-stacks \
  --output json | jq '.SolutionStacks[]' | grep -i "<language>"
```

### In-Place Migration (Direct Update)

**Warning:** Causes downtime during update. Best for non-production.

```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --solution-stack-name "64bit Amazon Linux 2023 v6.7.2 running Node.js 20" \
  --output json
```

### Blue/Green Migration (Zero Downtime - Recommended)

#### Step 1: Create New Environment on Target Platform
```bash
# Get current version
VERSION=$(aws elasticbeanstalk describe-environments \
  --environment-names <env-name> \
  --query 'Environments[0].VersionLabel' \
  --output text)

# Create environment on new platform
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <env-name>-migrated \
  --version-label $VERSION \
  --solution-stack-name "64bit Amazon Linux 2023 v6.7.2 running Node.js 20" \
  --cname-prefix <env-name>-migrated \
  --output json
```

#### Step 2: Wait for New Environment
```bash
aws elasticbeanstalk describe-environments \
  --environment-names <env-name>-migrated \
  --query 'Environments[0].{Status:Status,Health:Health}' \
  --output json
```

#### Step 3: Test New Environment
Verify at: `<env-name>-migrated.<region>.elasticbeanstalk.com`

#### Step 4: Swap CNAMEs
```bash
aws elasticbeanstalk swap-environment-cnames \
  --source-environment-name <env-name> \
  --destination-environment-name <env-name>-migrated \
  --output json
```

#### Step 5: Terminate Old Environment (after validation)
```bash
aws elasticbeanstalk terminate-environment \
  --environment-name <env-name> \
  --output json
```

### Common Migration Paths

| From | To | Notes |
|------|-----|-------|
| Amazon Linux 2 | Amazon Linux 2023 | Check for glibc/library compatibility |
| Node.js 16 | Node.js 20 | Update package.json engines |
| Python 3.8 | Python 3.11 | Check deprecated syntax |
| Java 8 (Corretto) | Java 17 (Corretto) | Update pom.xml/build.gradle |
| Docker (AL2) | Docker (AL2023) | Rebuild images if needed |

### Pre-Migration Checklist

1. **Review deprecations** - Check for removed APIs/features
2. **Test locally** - Run app on target runtime version
3. **Update dependencies** - Ensure compatibility with new platform
4. **Backup configuration** - Save current config template
5. **Plan rollback** - Keep old environment until verified

## Operations Role

### Associate Role
```bash
aws elasticbeanstalk associate-environment-operations-role \
  --environment-name <env-name> \
  --operations-role arn:aws:iam::<account>:role/aws-elasticbeanstalk-service-role \
  --output json
```

### Disassociate Role
```bash
aws elasticbeanstalk disassociate-environment-operations-role \
  --environment-name <env-name> \
  --output json
```

## Presenting Maintenance Info

Example output:
```
=== Maintenance: my-app-prod ===

Managed Updates: Enabled
Maintenance Window: Sunday 02:00 UTC
Update Level: minor

Pending Actions:
  1. Platform Update (PlatformUpdate)
     - Current: Node.js 20 v6.7.0
     - Target: Node.js 20 v6.7.2
     - Scheduled: 2024-01-21 02:00 UTC
     - Action ID: abc-123

Recent History:
  - 2024-01-14: Platform Update completed (v5.9.0 → v6.0.0)
  - 2024-01-07: Instance Refresh completed

To apply pending update now:
aws elasticbeanstalk apply-environment-managed-action \
  --environment-name my-app-prod \
  --action-id abc-123
```

## Error Handling

### No Pending Actions
```
No pending managed actions. Environment is up to date.
```

### Action Already In Progress
```
Cannot apply action - another update is in progress.
Check environment status:
aws elasticbeanstalk describe-environments --environment-names <env>
```

### Invalid Action ID
```
Action ID not found. List current pending actions:
aws elasticbeanstalk describe-environment-managed-actions --environment-name <env>
```

### Managed Updates Disabled
```
Managed updates not enabled. Enable with:
aws elasticbeanstalk update-environment \
  --environment-name <env> \
  --option-settings Namespace=aws:elasticbeanstalk:managedactions,OptionName=ManagedActionsEnabled,Value=true
```

## Composability

- **Check status after restart**: Use `status` skill
- **View logs**: Use `logs` skill
- **Monitor health**: Use `health` skill
- **Troubleshoot issues**: Use `troubleshoot` skill

## Additional Resources

For detailed reference information, see the shared reference files:

- [Configuration Options](../_shared/references/config-options.md) - All available configuration namespaces and options
- [Health States](../_shared/references/health-states.md) - Health colors, statuses, and thresholds
- [Cost Optimization](../_shared/references/cost-optimization.md) - Instance sizing, scaling, and cost-saving strategies
- [Platforms](../_shared/references/platforms.md) - Platform-specific configuration and requirements
