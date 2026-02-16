---
name: maintenance
description: Manages Elastic Beanstalk platform updates, application server restarts, managed actions, and maintenance windows. Use when user says "apply patches", "restart servers", "update beanstalk platform", "eb upgrade", "eb restart", "platform migration", "maintenance window", "pending updates", or "managed actions history". For configuration changes use config skill.
compatibility: Requires EB CLI (awsebcli) and AWS CLI with configured credentials.
license: MIT
allowed-tools:
  - Bash
metadata:
  author: shinmc
  version: 1.0.0
---

# Maintenance

Manage platform updates, restart application servers, and handle managed actions using the EB CLI.

## When to Use

- Upgrade platform version
- Restart application server
- Check pending managed actions
- Configure maintenance windows
- Perform platform migration (blue/green)

## When NOT to Use

- Configuration changes → use `config` skill
- Creating environments → use `environment` skill
- Deploying code → use `deploy` skill

---

## Platform Updates

```bash
eb status            # Check current platform
eb platform list     # List available platforms
eb upgrade           # Upgrade to latest
eb platform select   # Select different platform
```

## Restart Application Server

```bash
eb restart
eb restart <env-name>
```

## Pending Managed Actions

```bash
aws elasticbeanstalk describe-environment-managed-actions \
  --environment-name <env-name> --output json
```

## Managed Action History

```bash
aws elasticbeanstalk describe-environment-managed-action-history \
  --environment-name <env-name> --output json
```

## Configure Managed Updates

```bash
eb config
```

When `ManagedActionsEnabled` is `true`, you **must** also set `PreferredStartTime` and `UpdateLevel`:

```yaml
aws:elasticbeanstalk:managedactions:
  ManagedActionsEnabled: 'true'
  PreferredStartTime: 'Tue:09:00'    # Format: day:hour:minute (UTC)
aws:elasticbeanstalk:managedactions:platformupdate:
  UpdateLevel: minor                  # Values: patch | minor
```

- `patch` — patch version updates only (e.g., 2.0.7 → 2.0.8)
- `minor` — minor and patch updates (e.g., 2.0.8 → 2.1.0)

## Platform Migration (Blue/Green)

1. Clone environment: `eb clone <env> --clone_name <env>-migrated`
2. Select new platform: `eb platform select`
3. Test: `eb status && eb health && eb open`
4. Swap: `eb swap <env> --destination_name <env>-migrated`
5. Terminate old: `eb terminate <env> --force`

---

## Composability

- **Change configuration**: Use `config` skill
- **Manage environments**: Use `environment` skill
- **Check status**: Use `status` skill

## Additional Resources

- [Platforms](../_shared/references/platforms.md)
