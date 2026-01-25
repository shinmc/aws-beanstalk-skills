# AWS Elastic Beanstalk Skills

Agent skills for [AWS Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/), following the [Agent Skills](https://agentskills.io) open format.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/shinmc/aws-beanstalk-skills/main/scripts/install.sh | bash
```

Supports Claude Code, OpenAI Codex, OpenCode, and Cursor. Re-run to update.

### Manual Installation

<details>
<summary>Claude Code (skills)</summary>

```bash
# Clone the repo
git clone https://github.com/shinmc/aws-beanstalk-skills.git
cd aws-beanstalk-skills

# Copy skills to Claude skills directory
mkdir -p ~/.claude/skills
cp -r plugins/aws-beanstalk/skills/* ~/.claude/skills/

# Start a new Claude Code session to load the skills
```

To update, `git pull` and re-copy the skills.
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
| [status](plugins/aws-beanstalk/skills/status/SKILL.md) | Check environment status, deployments, and resources |
| [deploy](plugins/aws-beanstalk/skills/deploy/SKILL.md) | Deploy application versions to environments |
| [logs](plugins/aws-beanstalk/skills/logs/SKILL.md) | Request and retrieve logs, view events |
| [config](plugins/aws-beanstalk/skills/config/SKILL.md) | Read, validate, and update configuration |
| [health](plugins/aws-beanstalk/skills/health/SKILL.md) | Monitor environment and instance health |
| [troubleshoot](plugins/aws-beanstalk/skills/troubleshoot/SKILL.md) | Diagnose issues, suggest fixes, optimize costs |
| [environment](plugins/aws-beanstalk/skills/environment/SKILL.md) | Create, terminate, rebuild, swap environments |
| [app](plugins/aws-beanstalk/skills/app/SKILL.md) | Manage applications and versions |
| [maintenance](plugins/aws-beanstalk/skills/maintenance/SKILL.md) | Apply managed actions, platform updates |
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

### Full Lifecycle Management
- Create and manage environments
- Deploy and rollback versions
- Blue/green deployments with CNAME swap

### Monitoring & Troubleshooting
- Real-time health monitoring
- Log retrieval and analysis
- Automatic issue diagnosis

### Configuration Management
- Read and update environment settings
- Environment variable management
- Scaling and instance configuration

### Cost Optimization
- Instance right-sizing recommendations
- Idle environment detection
- Reserved instance guidance

## Hooks

This plugin includes a PreToolUse hook that auto-approves common AWS commands to avoid permission prompts:

- `aws elasticbeanstalk` - All Elastic Beanstalk operations
- `aws s3` - Deployment artifact uploads
- `aws cloudwatch` - Metrics for troubleshooting
- `curl` to AWS URLs - Log file retrieval

## Repository Structure

```
aws-beanstalk-skills/
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
│       ├── status/SKILL.md
│       ├── deploy/SKILL.md
│       ├── logs/SKILL.md
│       ├── config/SKILL.md
│       ├── health/SKILL.md
│       ├── troubleshoot/SKILL.md
│       ├── environment/SKILL.md
│       ├── app/SKILL.md
│       ├── maintenance/SKILL.md
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
        "cloudwatch:GetMetricStatistics",
        "logs:GetLogEvents"
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
