---
name: logs
description: Retrieves application logs, streams live logs, enables CloudWatch integration, and views environment events for Elastic Beanstalk. Use when user says "show me the logs", "what happened", "check errors", "deployment events", "eb logs", "eb events", "view logs", "get logs", "stream logs", "CloudWatch logs", or needs platform-specific log file paths. For troubleshooting use troubleshoot skill.
compatibility: Requires EB CLI (awsebcli) and AWS CLI with configured credentials.
license: MIT
allowed-tools:
  - Bash
metadata:
  author: shinmc
  version: 1.0.0
---

# Logs & Events

Retrieve application logs, stream live logs, enable CloudWatch logging, and view environment events using the EB CLI.

## When to Use

- View application logs
- Stream logs in real time
- Enable CloudWatch log integration
- Check environment events
- Find platform-specific log file paths

## When NOT to Use

- Interpreting errors and fixing issues → use `troubleshoot` skill
- Checking health status → use `status` skill
- Deploying code → use `deploy` skill

---

## Recent Logs

```bash
eb logs
eb logs <env-name>
eb logs --all            # All log files
eb logs --stream         # Stream logs live (Ctrl+C to stop)
eb logs --zip            # Download complete log bundle
eb logs --instance <id>  # Logs from specific instance
eb logs -g <log-group>   # Specific CloudWatch log group
```

## Enable CloudWatch Logs

```bash
eb logs --cloudwatch-logs enable
```

## Environment Events

```bash
eb events
eb events --follow       # Follow events live
```

## Platform-Specific Log Paths (via SSH)

**AL2/AL2023 (current platforms):**
- **Node.js**: `/var/log/web.stdout.log`, `/var/log/web.stderr.log`
- **Python**: `/var/log/web.stdout.log`, `/var/log/web.stderr.log`
- **Docker**: `/var/log/eb-docker/containers/eb-current-app/*.log`
- **Java (Corretto)**: `/var/log/web.stdout.log`, `/var/log/web.stderr.log`
- **Java (Tomcat)**: `/var/log/tomcat/catalina.out`
- **Go**: `/var/log/web.stdout.log`, `/var/log/web.stderr.log`
- **Ruby**: `/var/log/web.stdout.log`, `/var/log/web.stderr.log`
- **PHP**: `/var/log/web.stdout.log`, `/var/log/web.stderr.log`
- **.NET**: `/var/log/web.stdout.log`, `/var/log/web.stderr.log`

**Common EB platform logs:**
- `/var/log/eb-engine.log` — EB deployment engine log
- `/var/log/eb-hooks.log` — Platform hook execution log
- `/var/log/nginx/access.log`, `/var/log/nginx/error.log` — Reverse proxy logs

---

## Composability

- **Diagnose issues from logs**: Use `troubleshoot` skill
- **Check environment health**: Use `status` skill
- **Deploy code**: Use `deploy` skill

## Additional Resources

- [Health States](../_shared/references/health-states.md)
