---
name: eb-docs
description: Provides Elastic Beanstalk documentation, best practices, platform-specific guidance, and reference information for all 8 supported platforms. Use when user says "how do I", "beanstalk docs", "eb documentation", "beanstalk help", or needs platform guidance, .ebextensions examples, or .platform directory structure. For EB CLI operations use the dedicated skills. For AWS infrastructure use eb-infra skill.
compatibility: Requires EB CLI (awsebcli) and AWS CLI with configured credentials.
metadata:
  author: shinmc
  version: 1.0.0
---

# AWS Elastic Beanstalk Documentation (EB CLI)

Provide documentation, best practices, and reference information for Elastic Beanstalk using the EB CLI.

## When to Use

- User asks "how do I..." regarding Elastic Beanstalk
- User wants best practices or recommendations
- User needs platform-specific guidance
- User asks about EB concepts or architecture

## When NOT to Use

- Performing EB CLI operations → use the dedicated skills (`deploy`, `status`, `logs`, `config`, `environment`, `app`, `maintenance`)
- Diagnosing issues → use `troubleshoot` skill
- AWS infrastructure (SSL, domains, secrets, DB, security, monitoring, costs) → use `eb-infra` skill

## EB CLI Quick Reference

### Installation
```bash
pip install awsebcli
# or
brew install awsebcli
```

### Verify Installation
```bash
eb --version
```

### Initialize Project
```bash
eb init
```

### Core Commands

| Command | Description |
|---------|-------------|
| `eb init` | Initialize EB project |
| `eb create` | Create new environment |
| `eb deploy` | Deploy application |
| `eb status` | Show environment status |
| `eb health` | Show health status |
| `eb logs` | Get logs |
| `eb config` | Edit configuration |
| `eb terminate` | Terminate environment |
| `eb list` | List environments |
| `eb use` | Set default environment |
| `eb open` | Open in browser |
| `eb events` | Show recent events |
| `eb ssh` | SSH to instance |
| `eb scale` | Scale instances |
| `eb setenv` | Set environment variables |
| `eb printenv` | Show environment variables |
| `eb upgrade` | Upgrade platform |
| `eb clone` | Clone environment |
| `eb swap` | Swap environment URLs |
| `eb abort` | Abort in-progress update |
| `eb restore` | Restore terminated env |
| `eb appversion` | Manage app versions |
| `eb platform` | Platform operations |
| `eb console` | Open AWS Console |
| `eb tags` | Manage environment tags |
| `eb restart` | Restart app server |
| `eb codesource` | Configure CodeCommit integration |
| `eb local` | Run Docker app locally |
| `eb labs` | Experimental features |
| `eb migrate` | Migrate IIS apps to EB (Windows) |

## AWS Documentation Links

### General
- [Developer Guide](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/)
- [EB CLI Reference](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3.html)
- [API Reference](https://docs.aws.amazon.com/elasticbeanstalk/latest/api/)

### Platforms
- [Node.js](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create-deploy-nodejs.html)
- [Python](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create-deploy-python.html)
- [Java](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create-deploy-java.html)
- [Docker](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create-deploy-docker.html)
- [.NET](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create-deploy-dotnet.html)
- [Go](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create-deploy-go.html)
- [Ruby](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create-deploy-ruby.html)
- [PHP](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/create-deploy-php.html)

## Platform Best Practices

> For full platform details (all 8 platforms including configuration, examples, and comparison), see the [Platforms Reference](../_shared/references/platforms.md).

### Node.js
```
Project Structure:
├── package.json          # Required: dependencies & scripts
├── .npmrc                # Optional: npm configuration
├── Procfile              # Optional: custom start command
├── .ebignore             # Optional: files to exclude
└── .ebextensions/        # Optional: EB configuration

Key Settings:
- NODE_ENV=production
- npm start should work
- Listen on process.env.PORT (default: 8080)
```

### Python
```
Project Structure:
├── requirements.txt      # Required: pip dependencies
├── application.py        # WSGI application
├── Procfile             # Optional: custom command
├── .ebignore            # Optional: files to exclude
└── .ebextensions/       # Optional: EB configuration

Key Settings:
- WSGIPath: application:application
- NumProcesses, NumThreads for scaling
```

### Java
```
Project Structure:
├── target/app.war        # WAR file (Tomcat)
├── target/app.jar        # JAR file (standalone)
├── Procfile             # For JAR: web: java -jar app.jar
└── .ebextensions/       # Optional: EB configuration

Key Settings:
- JVM options via JAVA_OPTS
- Heap size configuration
```

### Docker
```
Project Structure:
├── Dockerfile            # Required for single container
├── docker-compose.yml    # For multi-container
├── .dockerignore        # Exclude files from build
└── .ebextensions/       # Optional: EB configuration

Key Settings:
- Expose port 80 or configure proxy
- Use multi-stage builds for smaller images
```

## .platform/ Directory (AL2 and AL2023)

On Amazon Linux 2 and AL2023, use `.platform/` for hooks and reverse proxy customization:

```
.platform/
├── hooks/                    # Run during deployments & platform updates
│   ├── prebuild/             # Before app build (install dependencies)
│   ├── predeploy/            # After build, before app deploy
│   └── postdeploy/           # After app deploy completes
├── confighooks/              # Run only on configuration changes
│   ├── prebuild/
│   ├── predeploy/
│   └── postdeploy/
└── nginx/
    ├── conf.d/               # Additional nginx config (*.conf)
    └── nginx.conf            # Full nginx config (replaces default)
```

Hook scripts must be executable (`chmod +x`). They run as root.

### Platform Hook Example

```bash
# .platform/hooks/postdeploy/01_restart_service.sh
#!/bin/bash
systemctl restart my-service
```

### Nginx Customization

```
# .platform/nginx/conf.d/client_max_body.conf
client_max_body_size 50M;
```

**Note:** `.ebextensions/` still works on AL2/AL2023 for option_settings and resources, but prefer `.platform/hooks/` over `.ebextensions/` commands/container_commands for lifecycle scripts.

## .ebextensions Examples

### Environment Variables
```yaml
# .ebextensions/env.config
option_settings:
  aws:elasticbeanstalk:application:environment:
    NODE_ENV: production
    LOG_LEVEL: info
```

### Packages
```yaml
# .ebextensions/packages.config
packages:
  yum:
    gcc: []
    make: []
```

### Commands
```yaml
# .ebextensions/commands.config
commands:
  01_create_dir:
    command: mkdir -p /var/app/logs
    ignoreErrors: true
```

### Files
```yaml
# .ebextensions/files.config
files:
  "/etc/nginx/conf.d/proxy.conf":
    mode: "000644"
    owner: root
    group: root
    content: |
      client_max_body_size 20M;
```

## .ebignore File

Create `.ebignore` to exclude files from deployment:
```
# Dependencies
node_modules/
.venv/
__pycache__/

# Build artifacts
dist/
build/
*.pyc

# Local config
.env
.env.local

# IDE
.idea/
.vscode/

# Git
.git/
```

## Experimental & Specialized Commands

### eb labs

Experimental features that may change or be removed in future versions:
```bash
eb labs --help    # List available lab commands
```

**Warning:** Do not rely on `eb labs` commands for production workflows.

### eb migrate (Windows IIS)

Migrates IIS sites from Windows servers to Elastic Beanstalk:
```bash
eb migrate --interactive                       # Interactive migration
eb migrate --sites "Default Web Site" --archive-only  # Archive without deploy
eb migrate explore --verbose                   # List available IIS sites
eb migrate cleanup                             # Clean up migration artifacts
```

Requires IIS 7.0+, Web Deploy 3.6+, and admin privileges. Windows only.

## Security Best Practices

### Environment Variables
- Never commit secrets to source control
- Use AWS Secrets Manager for sensitive values
- Use `eb setenv` for configuration
- Rotate credentials regularly

### IAM
- Use least-privilege instance profiles
- Separate roles for different environments
- Enable MFA for console access

### Network
- Use VPC with private subnets for instances
- Configure security groups restrictively
- Enable HTTPS with SSL certificate

## Troubleshooting Guide

### Common Issues

**"Environment health has transitioned from Ok to Severe"**
```bash
eb health    # Check health details
eb logs      # View application logs
eb events    # Check recent events
```

**"Deployment failed"**
```bash
eb events    # Check deployment errors
eb logs --all  # Get detailed logs
```

**"502 Bad Gateway"**
1. App not listening on correct port
2. App crashed on startup
3. Health check failing

**"High latency warnings"**
```bash
eb health --refresh  # Monitor metrics
eb scale 3           # Add more instances
```

## Presenting Documentation

When providing documentation:
1. Give direct answers first
2. Include relevant EB CLI commands
3. Link to official docs for more detail
4. Provide context for best practices

Example:
```
To set environment variables in Elastic Beanstalk:

1. Via EB CLI (recommended):
   eb setenv NODE_ENV=production API_KEY=secret

2. Via .ebextensions (committed to repo):
   # .ebextensions/env.config
   option_settings:
     aws:elasticbeanstalk:application:environment:
       NODE_ENV: production

3. View current variables:
   eb printenv

Best Practice: Use Secrets Manager for sensitive values.

See: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environments-cfg-softwaresettings.html
```

## Composability

- **Deploy code**: Use `deploy` skill
- **Check status & health**: Use `status` skill
- **View logs**: Use `logs` skill
- **Change configuration**: Use `config` skill
- **Troubleshoot issues**: Use `troubleshoot` skill
- **Manage environments**: Use `environment` skill
- **Manage applications**: Use `app` skill
- **Platform updates**: Use `maintenance` skill
- **AWS infrastructure** (SSL, domains, secrets, DB, security, monitoring, costs): Use `eb-infra` skill

## Additional Resources

For detailed reference information, see the shared reference files:

- [Configuration Options](../_shared/references/config-options.md) - All available configuration namespaces and options
- [Health States](../_shared/references/health-states.md) - Health colors, statuses, and thresholds
- [Cost Optimization](../_shared/references/cost-optimization.md) - Instance sizing, scaling, and cost-saving strategies
- [Platforms](../_shared/references/platforms.md) - Platform-specific configuration and requirements
