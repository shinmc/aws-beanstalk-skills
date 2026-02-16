---
name: deploy
description: Deploys application code to Elastic Beanstalk environments, manages versions, rollbacks, and deployment strategies. Use when user says "deploy", "push to EB", "eb deploy", "release", "rollback", "revert", "deploy to production", "CI/CD", "create version", ".ebignore", "deployment strategy", "eb codesource", "CodeCommit", "eb local", or "test locally". For environment creation use environment skill.
compatibility: Requires EB CLI (awsebcli) and AWS CLI with configured credentials.
license: MIT
allowed-tools:
  - Bash
metadata:
  author: shinmc
  version: 1.0.0
---

# Deploy to Elastic Beanstalk

Deploy application code, manage versions, rollback, and configure deployment strategies using the EB CLI.

## When to Use

- Deploy code to an environment
- Rollback to a previous version
- Configure deployment strategies (rolling, immutable, etc.)
- Create application versions without deploying
- Set up CI/CD integration
- Configure `.ebignore`
- Configure CodeCommit as deploy source
- Test Docker app locally before deploying

## When NOT to Use

- Creating new environments → use `environment` skill
- Checking status after deploy → use `status` skill
- Viewing deployment logs → use `logs` skill
- Changing configuration settings → use `config` skill

---

## Pre-Deploy Checklist

```bash
eb status    # Verify environment is Ready
eb health    # Verify health is Green
```

If health is Red or environment is Updating, do NOT deploy. Fix issues first.

## Quick Deploy

```bash
eb deploy
```

Deploy to specific environment:
```bash
eb deploy <env-name>
```

## Deploy with Version Label

```bash
eb deploy --label "v1.2.3"
eb deploy --label "v1.2.3" --message "Release v1.2.3 - Bug fixes"
```

## Deploy Staged Changes Only

```bash
eb deploy --staged
```

## Deploy Existing Version

```bash
eb deploy --version <version-label>
```

## Create Version Without Deploying

```bash
eb deploy --process
```

## Monitor Deployment

```bash
eb events --follow
```

## Post-Deploy Verification

```bash
eb status    # Confirm version deployed
eb health    # Confirm health is Green
eb events    # Check for warnings
eb open      # Open in browser
```

Look for:
- "New application version was deployed" — success
- "Environment health has transitioned from Ok to ..." — health degradation
- "Rolling back to version" — automatic rollback triggered

## Rollback

```bash
# List available versions
eb appversion

# Deploy previous known-good version
eb deploy --version <previous-version>

# Verify rollback
eb status
eb health
```

## Deployment Strategies

- **AllAtOnce** (Default) — Fastest, causes downtime
- **Rolling** — Updates in batches, maintains capacity
- **RollingWithAdditionalBatch** — Maintains full capacity
- **Immutable** — Safest, deploys to new instances
- **TrafficSplitting** — Canary deployments
- **Blue/Green** — CNAME swap (see `environment` skill)

Configure via `eb config`:
```yaml
aws:elasticbeanstalk:command:
  DeploymentPolicy: Rolling
  BatchSize: '30'
  BatchSizeType: Percentage
```

## .ebignore File

```
node_modules/
.venv/
__pycache__/
dist/
build/
.env
.env.local
.idea/
.vscode/
.git/
```

## Code Source (CodeCommit Integration)

```bash
eb codesource                  # Choose between CodeCommit and local
eb codesource codecommit       # Enable CodeCommit integration
eb codesource local            # Disable CodeCommit, use local source
```

**Note:** CodeCommit integration is not available in all AWS Regions.

## Local Testing (Docker)

Test Docker-based apps locally before deploying. Requires Docker installed. Linux/macOS only.

```bash
eb local run                   # Run containers locally
eb local run --port 8080       # Map to specific host port
eb local status                # Check local container status
eb local open                  # Open in browser
eb local logs                  # Show log file locations
eb local setenv KEY=value      # Set local env vars
eb local printenv              # View local env vars
```

## CI/CD Integration

```bash
eb deploy --nohang    # Non-interactive deploy
eb status --wait      # Wait for completion
eb health             # Verify healthy
```

---

## Composability

- **Check status after deploy**: Use `status` skill
- **View deployment logs**: Use `logs` skill
- **Change deployment config**: Use `config` skill
- **Create new environment**: Use `environment` skill
- **Manage app versions**: Use `app` skill

## Additional Resources

- [Configuration Options](../_shared/references/config-options.md)
- [Platforms](../_shared/references/platforms.md)
