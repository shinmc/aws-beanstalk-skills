# AWS Elastic Beanstalk Skills

Agent skills for [AWS Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/), following the [Agent Skills](https://agentskills.io) open format.

**Website:** [aws-beanstalk-skills.vercel.app](https://aws-beanstalk-skills.vercel.app)

## Installation

```bash
npx skills add shinmc/aws-beanstalk-skills
```

Or via install script:

```bash
curl -fsSL https://raw.githubusercontent.com/shinmc/aws-beanstalk-skills/main/scripts/install.sh | bash
```

Supports Claude Code, OpenAI Codex, OpenCode, and Cursor. Re-run to update.

### Manual Installation

<details>
<summary>Claude Code plugin</summary>

```bash
claude plugin marketplace add shinmc/aws-beanstalk-skills
claude plugin install aws-beanstalk@aws-beanstalk-skills
```

</details>

<details>
<summary>Local skills copy (any agent)</summary>

Copy `plugins/aws-beanstalk/skills/` to your agent's skills directory:
- Claude: `~/.claude/skills/`
- Codex: `~/.codex/skills/`
- OpenCode: `~/.config/opencode/skill/`
- Cursor: `~/.cursor/skills/`
</details>

## Prerequisites

- AWS CLI installed and configured (`aws configure`)
- IAM permissions for Elastic Beanstalk operations
- `jq` installed for JSON parsing
- Works on Linux and macOS (platform-specific commands provided where needed)

## Available Skills

| Skill | Description |
|-------|-------------|
| [eb](plugins/aws-beanstalk/skills/eb/SKILL.md) | General entry point, quick reference |
| [deploy](plugins/aws-beanstalk/skills/deploy/SKILL.md) | Deploy application versions, rollback, CI/CD |
| [status](plugins/aws-beanstalk/skills/status/SKILL.md) | Check environment status and health |
| [logs](plugins/aws-beanstalk/skills/logs/SKILL.md) | View logs, stream events, CloudWatch |
| [config](plugins/aws-beanstalk/skills/config/SKILL.md) | Read, update configuration, env vars, scaling |
| [troubleshoot](plugins/aws-beanstalk/skills/troubleshoot/SKILL.md) | Diagnose issues, common fixes |
| [environment](plugins/aws-beanstalk/skills/environment/SKILL.md) | Create, terminate, clone, swap environments |
| [app](plugins/aws-beanstalk/skills/app/SKILL.md) | Manage applications and versions |
| [maintenance](plugins/aws-beanstalk/skills/maintenance/SKILL.md) | Platform updates, managed actions |
| [eb-infra](plugins/aws-beanstalk/skills/eb-infra/SKILL.md) | SSL, domains, secrets, database, security, costs |
| [eb-docs](plugins/aws-beanstalk/skills/eb-docs/SKILL.md) | Documentation and best practices |

## Supported Platforms

- Node.js
- Python
- Java (Corretto/Tomcat)
- Docker
- .NET
- Go
- Ruby
- PHP

## Features

### Deployment & Lifecycle
- Deploy, rollback, and manage application versions
- Blue/green deployments with CNAME swap
- Create, terminate, clone, and restore environments
- Deployment strategies (rolling, immutable, traffic splitting)
- CodeCommit integration and local Docker testing

### Monitoring & Troubleshooting
- Real-time health monitoring with `eb health --refresh`
- AWS CLI health inspection (`describe-environment-health`, `describe-instances-health`)
- Log retrieval, streaming, and CloudWatch integration
- Structured diagnostic workflow (status → health → events → logs → config → SSH)

### Configuration & Maintenance
- Interactive config editor, environment variables, scaling
- Platform updates, managed actions, and maintenance windows
- `.platform/` hooks and nginx customization (AL2/AL2023)
- Solution stack validation

### Infrastructure (eb-infra)
- SSL/TLS certificate management (ACM)
- Custom domain setup (Route 53)
- Secrets management (Secrets Manager, SSM Parameter Store)
- Database monitoring (RDS)
- Security auditing (IAM, security groups, VPC)
- Cost analysis (Cost Explorer)
- CloudWatch alarms and SNS notifications

### Documentation & Best Practices
- Platform-specific guidance (Node.js, Python, Java, Docker, .NET, Go, Ruby, PHP)
- `.ebextensions` and `.platform/` examples
- Security best practices and common pitfalls

## Hooks

This plugin includes a PreToolUse hook that auto-approves common AWS commands to avoid permission prompts:

- `eb` CLI - All EB CLI commands
- `aws elasticbeanstalk` - All Elastic Beanstalk API operations
- `aws s3` - Deployment artifact uploads (excludes `rm`, `rb`, `mv`, `sync --delete`)
- `aws cloudwatch` - Metrics and monitoring
- `aws ec2` - Instance and security group inspection (describe only)
- `aws elbv2` - Load balancer health checks (describe only)
- `aws autoscaling` - Auto scaling group inspection (describe only)
- `aws acm` - SSL certificate management
- `aws route53` - Custom domain management
- `aws secretsmanager` - Secrets management (excludes `delete-secret`, `delete-resource-policy`)
- `aws ssm` - SSM Parameter Store
- `aws rds` - Database monitoring (describe/snapshot only)
- `aws ce` - Cost Explorer analysis
- `aws sns` - Monitoring alarm notifications
- `aws iam` - EB role management (EB-related only)
- `curl` to AWS URLs - Log file retrieval

## Repository Structure

```
aws-beanstalk-skills/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/aws-beanstalk/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── hooks/
│   │   ├── hooks.json
│   │   └── auto-approve-aws.sh
│   └── skills/
│       ├── _shared/
│       │   ├── scripts/
│       │   │   └── eb-api.sh
│       │   └── references/
│       │       ├── config-options.md
│       │       ├── health-states.md
│       │       ├── platforms.md
│       │       └── cost-optimization.md
│       ├── eb/SKILL.md
│       ├── deploy/SKILL.md
│       ├── status/SKILL.md
│       ├── logs/SKILL.md
│       ├── config/SKILL.md
│       ├── troubleshoot/SKILL.md
│       ├── environment/SKILL.md
│       ├── app/SKILL.md
│       ├── maintenance/SKILL.md
│       ├── eb-infra/SKILL.md
│       └── eb-docs/SKILL.md
├── scripts/
│   ├── install.sh
│   └── sync-shared.sh
└── README.md
```

## Creating New Skills

Create `plugins/aws-beanstalk/skills/{name}/SKILL.md`:

```yaml
---
name: my-skill
description: What this skill does and when to use it
allowed-tools: Bash(aws elasticbeanstalk:*)
---

# Instructions

Step-by-step guidance for the agent.

## Examples

Concrete examples showing expected input/output.
```

## Development

### Shared Files

Scripts (`eb-api.sh`) and references are shared across skills.
Canonical versions live in `plugins/aws-beanstalk/skills/_shared/`.

After editing files in `_shared/`, run:
```bash
./scripts/sync-shared.sh
```

This copies shared files to each skill that needs them.

## Required IAM Permissions

For full functionality, the IAM user/role needs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticbeanstalk:*",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeSecurityGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeLoadBalancers",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeScalingActivities",
        "cloudwatch:GetMetricStatistics",
        "logs:GetLogEvents",
        "acm:ListCertificates",
        "acm:DescribeCertificate",
        "acm:RequestCertificate",
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets",
        "route53:GetChange",
        "secretsmanager:*",
        "ssm:GetParameter",
        "ssm:GetParametersByPath",
        "ssm:PutParameter",
        "ssm:DescribeParameters",
        "rds:DescribeDBInstances",
        "rds:DescribeDBSnapshots",
        "rds:CreateDBSnapshot",
        "rds:DescribePendingMaintenanceActions",
        "ce:GetCostAndUsage",
        "ce:GetCostForecast",
        "sns:CreateTopic",
        "sns:Subscribe",
        "sns:ListTopics",
        "iam:GetRole",
        "iam:GetInstanceProfile"
      ],
      "Resource": "*"
    }
  ]
}
```

For production, scope resources appropriately.

## References

- [AWS Elastic Beanstalk Developer Guide](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/)
- [AWS CLI Elastic Beanstalk Reference](https://docs.aws.amazon.com/cli/latest/reference/elasticbeanstalk/)
- [Agent Skills Specification](https://agentskills.io/specification)

## License

MIT
