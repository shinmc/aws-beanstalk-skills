---
name: eb
description: General Elastic Beanstalk entry point. Use when user says "eb", "beanstalk", "elastic beanstalk" without a specific action, or needs help choosing the right EB skill. For specific tasks, prefer the dedicated skill (deploy, status, logs, config, troubleshoot, environment, app, maintenance, eb-infra, eb-docs).
---

# AWS Elastic Beanstalk (EB CLI)

General entry point for Elastic Beanstalk. For specific tasks, use the dedicated skill.

## Prerequisites

**EB CLI must be installed:**
```bash
pip install awsebcli
# or
brew install awsebcli
```

**Project must be initialized:**
```bash
eb init
# Or non-interactive:
eb init <app-name> --region <region> --platform "<platform>"
```

## Quick Reference

| Task | Skill | Key Commands |
|------|-------|-------------|
| Deploy code | `deploy` | `eb deploy`, rollback, CI/CD, `eb codesource`, `eb local` |
| Check status & health | `status` | `eb status`, `eb list`, `eb health` |
| View logs & events | `logs` | `eb logs`, `eb events` |
| Configuration | `config` | `eb config`, `eb setenv`, `eb scale` |
| Troubleshoot | `troubleshoot` | Diagnostic workflow, common fixes |
| Environments | `environment` | `eb create`, `eb terminate`, `eb clone`, `eb swap` |
| Applications | `app` | `eb init`, `eb appversion`, lifecycle |
| Maintenance | `maintenance` | `eb upgrade`, `eb restart`, managed actions |
| Infrastructure | `eb-infra` | SSL, domains, secrets, database, security, costs |
| Documentation | `eb-docs` | Best practices, platform guides, `eb labs`, `eb migrate` |

## Error Reference

| Error | Solution |
|-------|----------|
| Not initialized | `eb init` |
| No environment found | `eb list` then `eb use <env>` |
| Credentials not configured | `aws configure` |
| CNAME already taken | `eb create <env> --cname <different-prefix>` |
| Environment limit reached | Terminate unused environments |
| Deployment in progress | `eb status` to check, `eb abort` to cancel |

## Composability

- **Deploy code**: Use `deploy` skill
- **Check status & health**: Use `status` skill
- **View logs & events**: Use `logs` skill
- **Change configuration**: Use `config` skill
- **Diagnose problems**: Use `troubleshoot` skill
- **Manage environments**: Use `environment` skill
- **Manage applications**: Use `app` skill
- **Platform updates & restarts**: Use `maintenance` skill
- **SSL, domains, secrets, DB, security, monitoring, costs**: Use `eb-infra` skill
- **Documentation & best practices**: Use `eb-docs` skill

## Additional Resources

- [Configuration Options](../_shared/references/config-options.md)
- [Health States](../_shared/references/health-states.md)
- [Cost Optimization](../_shared/references/cost-optimization.md)
- [Platforms](../_shared/references/platforms.md)
