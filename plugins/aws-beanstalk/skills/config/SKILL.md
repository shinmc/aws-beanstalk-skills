---
name: config
description: Reads and modifies Elastic Beanstalk environment configuration including environment variables, scaling, instance types, and tags. Use when user says "show config", "change settings", "environment variables", "eb config", "eb setenv", "eb printenv", "eb scale", "change instance type", "configure scaling", "HTTPS listener", "config template", or "tags". For environment creation use environment skill. For SSL setup use eb-infra skill.
compatibility: Requires EB CLI (awsebcli) and AWS CLI with configured credentials.
license: MIT
allowed-tools:
  - Bash
metadata:
  author: shinmc
  version: 1.0.0
---

# Configuration

Read, update, and manage Elastic Beanstalk environment configuration using the EB CLI.

## When to Use

- View or edit environment configuration
- Set or view environment variables
- Scale instances
- Save/apply configuration templates
- Manage environment tags
- Configure HTTPS, scaling, instance type, enhanced health

## When NOT to Use

- Creating environments → use `environment` skill
- SSL certificate management → use `eb-infra` skill
- Deploying code → use `deploy` skill
- Secrets Manager / SSM → use `eb-infra` skill

---

## Interactive Config Editor

> **Note:** `eb config` opens an interactive editor (`$EDITOR`). For non-interactive use, prefer `aws elasticbeanstalk describe-configuration-settings` to read and `aws elasticbeanstalk update-environment --option-settings` to write.

```bash
eb config
eb config <env-name>
```

## Environment Variables

```bash
eb printenv                              # View
eb printenv <env-name>                   # View specific env
eb setenv KEY1=value1 KEY2=value2        # Set
eb setenv KEY1=                          # Remove
```

## Quick Scale

```bash
eb scale <number>
eb scale <number> <env-name>
```

## Save/Apply Configuration Templates

```bash
eb config save --cfg <config-name>       # Save
eb config --cfg <config-name>            # Apply
```

## Validate Configuration Before Applying

```bash
aws elasticbeanstalk validate-configuration-settings \
  --application-name <app-name> \
  --environment-name <env-name> \
  --option-settings file://options.json \
  --output json
```

## Tag Management

```bash
eb tags --list                           # List tags
eb tags --add "Team=backend,Env=prod"    # Add
eb tags --update "Env=staging"           # Update
eb tags --delete "OldTag"                # Delete
```

## Common Configuration Tasks

**HTTPS listener:**
```yaml
aws:elbv2:listener:443:
  ListenerEnabled: 'true'
  Protocol: HTTPS
  SSLCertificateArns: arn:aws:acm:region:account:certificate/cert-id
```

**Scaling:**
```yaml
aws:autoscaling:asg:
  MinSize: '2'
  MaxSize: '10'
aws:autoscaling:trigger:
  MeasureName: CPUUtilization
  UpperThreshold: '70'
```

**Instance type:**
```yaml
aws:autoscaling:launchconfiguration:
  InstanceType: t3.medium
```

**Enhanced health:**
```yaml
aws:elasticbeanstalk:healthreporting:system:
  SystemType: enhanced
```

## Platform Gotchas

**AL2023/AL2 Node.js:** The `aws:elasticbeanstalk:container:nodejs` namespace (NodeCommand, NodeVersion, etc.) is **NOT supported** on Amazon Linux 2 or AL2023. It only works on legacy Amazon Linux 1 (AMI). On AL2/AL2023, use a `Procfile` instead:

```
# Procfile
web: node app.js
```

---

## Composability

- **Deploy after config change**: Use `deploy` skill
- **Check status**: Use `status` skill
- **Create new environment**: Use `environment` skill
- **SSL/secrets/database config**: Use `eb-infra` skill

## Additional Resources

- [Configuration Options](../_shared/references/config-options.md)
- [Cost Optimization](../_shared/references/cost-optimization.md)
