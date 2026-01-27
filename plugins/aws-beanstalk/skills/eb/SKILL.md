---
name: eb
description: Main entrypoint for AWS Elastic Beanstalk operations. Use when user says "eb", "beanstalk", "elastic beanstalk", "aws eb", "check my beanstalk", "my aws environments", or any Beanstalk-related request. Routes to specialized skills as needed.
argument-hint: "[command or question]"
allowed-tools: Bash(aws elasticbeanstalk:*), Bash(aws cloudwatch:*), Bash(aws ec2:*), Bash(aws s3:*), Bash(curl:*), Bash(scripts/eb-api.sh:*), WebFetch
---

# AWS Elastic Beanstalk

Main entrypoint for all Elastic Beanstalk operations. This skill routes requests to specialized skills or handles them directly.

## How to Use

Users can invoke this skill with `/eb` followed by what they want to do:
- `/eb status` - Check environment status
- `/eb deploy` - Deploy code
- `/eb logs` - View logs
- `/eb health` - Check health metrics
- `/eb config` - View/modify configuration
- `/eb troubleshoot` - Diagnose issues
- `/eb create environment` - Create new environment
- `/eb help` - Show available commands

## Routing Guide

Based on the user's request, route to the appropriate specialized skill:

| User Intent | Route To |
|-------------|----------|
| Status, what's running, is it deployed | `status` skill |
| Logs, events, errors, what happened | `logs` skill |
| Health, why yellow/red, CPU/memory | `health` skill |
| Config, settings, environment variables | `config` skill |
| Deploy, push code, create version | `deploy` skill |
| Create/terminate/swap environments | `environment` skill |
| Create/delete applications | `app` skill |
| Platform updates, patches, restart | `maintenance` skill |
| Diagnose issues, fix problems, optimize | `troubleshoot` skill |
| Documentation, how do I, best practices | `eb-docs` skill |

## Quick Commands

If the user just says `/eb` without specifics, show available environments:

```bash
aws elasticbeanstalk describe-environments \
  --query 'Environments[].{Name:EnvironmentName,Status:Status,Health:Health,App:ApplicationName,URL:CNAME}' \
  --output table
```

### List Applications
```bash
aws elasticbeanstalk describe-applications \
  --query 'Applications[].{Name:ApplicationName,Created:DateCreated}' \
  --output table
```

### Quick Health Check
```bash
aws elasticbeanstalk describe-environments \
  --query 'Environments[].{Name:EnvironmentName,Health:Health,HealthStatus:HealthStatus}' \
  --output table
```

## Response Format

When showing environment overview:
```
=== Elastic Beanstalk Environments ===

Application: my-app
  - my-app-prod (Ready, Green) - my-app-prod.elasticbeanstalk.com
  - my-app-staging (Ready, Yellow) - my-app-staging.elasticbeanstalk.com

Application: api-service
  - api-prod (Ready, Green) - api-prod.elasticbeanstalk.com

For details on a specific environment, try:
  /eb status <env-name>
  /eb health <env-name>
  /eb logs <env-name>
```

## Help Response

When user asks for help, show:
```
AWS Elastic Beanstalk Commands:

  /eb                    List all environments
  /eb status [env]       Environment status and deployment info
  /eb health [env]       Detailed health metrics
  /eb logs [env]         View application and error logs
  /eb config [env]       View/modify configuration
  /eb deploy [version]   Deploy code to environment
  /eb troubleshoot [env] Diagnose issues and get recommendations

Environment Management:
  /eb create environment Create new environment
  /eb terminate [env]    Terminate environment
  /eb swap [env1] [env2] Swap environment CNAMEs

Other:
  /eb docs [topic]       Documentation and best practices
  /eb maintenance [env]  Platform updates and patches
```

## Composability

This skill acts as a router. For detailed operations, it should guide users to specialized skills:

- **Detailed status**: Use `status` skill
- **View logs**: Use `logs` skill
- **Health metrics**: Use `health` skill
- **Configuration**: Use `config` skill
- **Deployments**: Use `deploy` skill
- **Environment lifecycle**: Use `environment` skill
- **Application management**: Use `app` skill
- **Maintenance**: Use `maintenance` skill
- **Troubleshooting**: Use `troubleshoot` skill
- **Documentation**: Use `eb-docs` skill
