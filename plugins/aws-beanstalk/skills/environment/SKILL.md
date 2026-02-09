---
name: environment
description: This skill should be used when the user wants to create, terminate, clone, swap, abort, or restore Elastic Beanstalk environments, says "eb create", "eb terminate", "eb clone", "eb swap", "new environment", "delete environment", "blue/green", "CNAME swap", "abort update", "restore environment", or "DNS availability". For deploying to an existing environment use deploy skill. For configuration changes use config skill.
---

# Environment Management

Create, terminate, clone, swap, abort, and restore Elastic Beanstalk environments using the EB CLI.

## When to Use

- Create a new environment
- Terminate an environment
- Clone an environment
- Swap URLs (blue/green deployment)
- Abort an in-progress update
- Restore a terminated environment
- Check DNS availability for CNAME

## When NOT to Use

- Deploying to an existing environment → use `deploy` skill
- Changing configuration → use `config` skill
- Checking status → use `status` skill
- Platform updates → use `maintenance` skill

---

## Destructive Operations Warning

Before terminate/restore: **verify environment name**, **check traffic**, **confirm with user**.

## Solution Stack Validation

Before creating, verify the platform solution stack name:
```bash
aws elasticbeanstalk list-available-solution-stacks --output json --query 'SolutionStacks'
```

Solution stack name format: `64bit Amazon Linux 2023 v6.7.3 running Node.js 24`

## Create Environment

```bash
eb create <env-name>
eb create <env-name> --instance_type t3.medium
eb create <env-name> --elb-type application
eb create <env-name> --single                    # No load balancer
eb create <env-name> --scale 2
eb create <env-name> --envvars KEY1=val1,KEY2=val2
eb create <env-name> --tags Env=production
eb create <env-name> --cname <prefix>
eb create <env-name> --tier worker
```

## DNS Availability Check (before create with custom CNAME)

```bash
aws elasticbeanstalk check-dns-availability \
  --cname-prefix <desired-prefix> --output json
```

## Terminate

```bash
eb terminate <env-name>
eb terminate <env-name> --force
```

## Clone

```bash
eb clone <source-env> --clone_name <new-env>
```

## Swap URLs (Blue/Green)

```bash
eb swap <env1> --destination_name <env2>
```

## Abort In-Progress Update

```bash
eb abort
```

## Restore Terminated Environment

```bash
eb restore --list
eb restore <env-id>
```

---

## Composability

- **Deploy to new environment**: Use `deploy` skill
- **Configure new environment**: Use `config` skill
- **Check environment status**: Use `status` skill
- **Platform migration**: Use `maintenance` skill

## Additional Resources

- [Configuration Options](../_shared/references/config-options.md)
- [Cost Optimization](../_shared/references/cost-optimization.md)
