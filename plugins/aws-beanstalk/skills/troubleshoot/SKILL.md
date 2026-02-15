---
name: troubleshoot
description: Diagnoses and resolves Elastic Beanstalk issues using a structured workflow of status, health, events, logs, config, and SSH inspection. Use when user says "why is it failing", "what's wrong", "my beanstalk is broken", "debug beanstalk", "health check failure", "deployment failed", "high latency", "out of memory", "502 bad gateway", "red health", or "yellow health". For viewing raw logs use logs skill. For routine status checks use status skill.
compatibility: Requires EB CLI (awsebcli) and AWS CLI with configured credentials.
metadata:
  author: shinmc
  version: 1.0.0
---

# Troubleshoot

Diagnose issues, debug failures, and resolve common Elastic Beanstalk problems using a structured workflow.

## When to Use

- Environment is unhealthy (red/yellow)
- Deployment failed
- Application errors or crashes
- High latency or performance issues
- Health check failures
- 502 Bad Gateway errors
- Out of memory issues
- Database connection problems

## When NOT to Use

- Routine status checks → use `status` skill
- Just viewing logs → use `logs` skill
- Changing configuration → use `config` skill

---

**Diagnostic workflow: Status → Health → Events → Logs → Config → SSH**

## Step 1: Check Status and Health

```bash
eb status
eb health
```

## Step 2: Check Recent Events

```bash
eb events
```

## Step 3: Get Logs

```bash
eb logs
eb logs --all
```

## Step 4: Check Configuration

```bash
# View config (non-interactive):
aws elasticbeanstalk describe-configuration-settings \
  --application-name <app-name> \
  --environment-name <env-name> --output json

# View environment variables:
eb printenv
```

## Step 5: Inspect Health via AWS CLI

Environment-level health (requires enhanced health reporting):
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name <env-name> \
  --attribute-names All --output json
```

Per-instance health (requires enhanced health reporting):
```bash
aws elasticbeanstalk describe-instances-health \
  --environment-name <env-name> \
  --attribute-names All --output json
```

Provisioned resources:
```bash
aws elasticbeanstalk describe-environment-resources \
  --environment-name <env-name> --output json
```

Check individual instance status:
```bash
aws ec2 describe-instance-status --instance-ids <id> --output json
```

Check load balancer target health:
```bash
aws elbv2 describe-target-health --target-group-arn <arn> --output json
```

## Step 6: SSH to Instance

```bash
eb ssh
eb ssh --instance <instance-id>
```

Common SSH debugging:
```bash
tail -f /var/log/web.stdout.log
tail -f /var/log/web.stderr.log
cat /var/log/eb-engine.log | grep -i error
top
free -m
df -h
curl localhost:80/health
```

## Common Issues & Fixes

**Health Check Failures (Red/Yellow):**
1. Health check path wrong → `eb config` → set `HealthCheckPath = /health`
2. App too slow to start → increase health check interval
3. Port mismatch → check `eb printenv` for PORT

**Deployment Failures:**
1. Build failed → check package.json/requirements.txt
2. App crash on start → check start command, verify env vars: `eb printenv`
3. Permissions → check IAM instance profile

**High Latency:**
1. Scale up: `eb config` → change InstanceType
2. Add instances: `eb scale 3`
3. Enable caching

**Out of Memory:**
1. Upgrade instance type
2. `eb ssh` → `dmesg | grep -i oom`

**Database Connection Issues:**
1. Check env vars: `eb printenv | grep DATABASE`
2. Security groups: use `eb-infra` skill (security)
3. RDS status: use `eb-infra` skill (database)

For common EB CLI error messages and solutions, see the `eb` skill (Error Reference table).

---

## Composability

- **View raw logs**: Use `logs` skill
- **Check status/health**: Use `status` skill
- **Change configuration**: Use `config` skill
- **Database/security issues**: Use `eb-infra` skill
- **Documentation**: Use `eb-docs` skill

## Additional Resources

- [Health States](../_shared/references/health-states.md)
- [Configuration Options](../_shared/references/config-options.md)
