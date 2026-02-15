---
name: status
description: Checks Elastic Beanstalk environment status, health, and deployment state. Lists environments and opens them in browser or AWS Console. Use when user says "eb status", "environment status", "what's running", "is it deployed", "check environments", "list environments", "eb health", "eb list", "eb open", "eb console", "is it healthy", or "how is my beanstalk". For troubleshooting use troubleshoot skill. For logs use logs skill.
compatibility: Requires EB CLI (awsebcli) and AWS CLI with configured credentials.
metadata:
  author: shinmc
  version: 1.0.0
---

# Environment Status & Health

Check current deployment state, environment health, and list Elastic Beanstalk environments using the EB CLI.

## When to Use

- Check environment status or deployment state
- List all environments
- View health overview
- Open environment in browser or AWS Console
- Check provisioned resources

## When NOT to Use

- Viewing logs → use `logs` skill
- Diagnosing problems → use `troubleshoot` skill
- Changing configuration → use `config` skill
- Deploying code → use `deploy` skill

---

## Quick Status

```bash
eb status
eb status <env-name>
```

## List All Environments

```bash
eb list
eb list --verbose
```

## Set Default Environment

```bash
eb use <env-name>
```

## Open in Browser

```bash
eb open
eb open <env-name>
```

## Open AWS Console

```bash
eb console
eb console <env-name>
```

## Detailed Health

```bash
eb health
eb health <env-name>
eb health --refresh    # Live-updating dashboard
```

Health colors: **Green** (OK), **Yellow** (Warning), **Red** (Degraded/Severe), **Grey** (Unknown)

## Environment Health (AWS CLI)

Detailed health via AWS CLI (requires enhanced health reporting):
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name <env-name> \
  --attribute-names All --output json
```

Per-instance health:
```bash
aws elasticbeanstalk describe-instances-health \
  --environment-name <env-name> \
  --attribute-names All --output json
```

## Provisioned Resources

```bash
aws elasticbeanstalk describe-environment-resources \
  --environment-name <env-name> \
  --output json
```

Shows EC2 instances, load balancers, auto scaling groups, and triggers.

---

## Composability

- **View logs**: Use `logs` skill
- **Diagnose issues**: Use `troubleshoot` skill
- **Deploy code**: Use `deploy` skill
- **Change configuration**: Use `config` skill

## Additional Resources

- [Health States](../_shared/references/health-states.md)
