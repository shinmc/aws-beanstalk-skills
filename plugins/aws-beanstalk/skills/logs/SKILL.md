---
name: logs
description: This skill should be used when the user asks for logs, events, "show me the logs", "what happened", "check errors", "deployment events", "eb logs", "eb events", "view logs", "get logs", "stream logs", "CloudWatch logs", or needs platform-specific log file paths. For troubleshooting based on log content use troubleshoot skill.
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

- **Node.js**: `/var/log/web.stdout.log`, `/var/log/web.stderr.log`
- **Python**: `/var/log/web.stdout.log`, `/opt/python/log/`
- **Docker**: `/var/log/eb-docker/containers/`
- **Java**: `/var/log/tomcat/catalina.out`

---

## Composability

- **Diagnose issues from logs**: Use `troubleshoot` skill
- **Check environment health**: Use `status` skill
- **Deploy code**: Use `deploy` skill

## Additional Resources

- [Health States](../_shared/references/health-states.md)
