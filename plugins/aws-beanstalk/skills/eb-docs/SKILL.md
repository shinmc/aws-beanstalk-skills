---
name: eb-docs
description: This skill should be used when the user asks about Elastic Beanstalk documentation, best practices, "how do I", platform-specific guidance, or needs reference information.
argument-hint: "[topic]"
allowed-tools: Bash(curl:*), WebFetch
---

# AWS Elastic Beanstalk Documentation

Provide documentation, best practices, and reference information for Elastic Beanstalk.

## When to Use

- User asks "how do I..." regarding Elastic Beanstalk
- User wants best practices or recommendations
- User needs platform-specific guidance
- User asks about EB concepts or architecture

## AWS Documentation Links

### General
- [Developer Guide](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/)
- [CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/elasticbeanstalk/)
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

### Configuration
- [Configuration Options](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options.html)
- [Environment Properties](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environments-cfg-softwaresettings.html)
- [Auto Scaling](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.managing.as.html)

## Platform Best Practices

### Node.js
```
Project Structure:
├── package.json          # Required: dependencies & scripts
├── .npmrc                 # Optional: npm configuration
├── Procfile              # Optional: custom start command
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

## Configuration Best Practices

### Health Checks
```bash
# Custom health check endpoint
aws elasticbeanstalk update-environment \
  --environment-name <env> \
  --option-settings \
    Namespace=aws:elasticbeanstalk:environment:process:default,OptionName=HealthCheckPath,Value=/health \
    Namespace=aws:elasticbeanstalk:environment:process:default,OptionName=HealthCheckInterval,Value=15
```

### Auto Scaling
```bash
# Recommended settings for production
aws elasticbeanstalk update-environment \
  --environment-name <env> \
  --option-settings \
    Namespace=aws:autoscaling:asg,OptionName=MinSize,Value=2 \
    Namespace=aws:autoscaling:asg,OptionName=MaxSize,Value=10 \
    Namespace=aws:autoscaling:trigger,OptionName=MeasureName,Value=CPUUtilization \
    Namespace=aws:autoscaling:trigger,OptionName=Unit,Value=Percent \
    Namespace=aws:autoscaling:trigger,OptionName=LowerThreshold,Value=20 \
    Namespace=aws:autoscaling:trigger,OptionName=UpperThreshold,Value=70
```

### Enhanced Health
```bash
# Enable enhanced health monitoring
aws elasticbeanstalk update-environment \
  --environment-name <env> \
  --option-settings \
    Namespace=aws:elasticbeanstalk:healthreporting:system,OptionName=SystemType,Value=enhanced
```

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

## Security Best Practices

### Environment Variables
- Never commit secrets to source control
- Use AWS Secrets Manager for sensitive values
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
1. Check instance health: `describe-instances-health`
2. View logs: request-environment-info
3. Check events for errors

**"Deployment failed"**
1. Check build logs
2. Verify package.json/requirements.txt
3. Test locally first

**"502 Bad Gateway"**
1. App not listening on correct port
2. App crashed on startup
3. Health check failing

**"High latency warnings"**
1. Check instance CPU/memory
2. Review database performance
3. Consider scaling up/out

## Presenting Documentation

When providing documentation:
1. Give direct answers first
2. Include relevant code examples
3. Link to official docs for more detail
4. Provide context for best practices

Example:
```
To set environment variables in Elastic Beanstalk:

1. Via CLI:
   aws elasticbeanstalk update-environment \
     --environment-name my-app-prod \
     --option-settings Namespace=aws:elasticbeanstalk:application:environment,OptionName=API_KEY,Value=secret

2. Via .ebextensions (committed to repo):
   # .ebextensions/env.config
   option_settings:
     aws:elasticbeanstalk:application:environment:
       NODE_ENV: production

Best Practice: Use Secrets Manager for sensitive values and reference them in your application code rather than storing them as plain environment variables.

See: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environments-cfg-softwaresettings.html
```

## Composability

- **Apply configuration**: Use `config` skill
- **Deploy changes**: Use `deploy` skill
- **Create environments**: Use `environment` skill
- **Troubleshoot**: Use `troubleshoot` skill

## Additional Resources

For detailed reference information, see the shared reference files:

- [Configuration Options](../_shared/references/config-options.md) - All available configuration namespaces and options
- [Health States](../_shared/references/health-states.md) - Health colors, statuses, and thresholds
- [Cost Optimization](../_shared/references/cost-optimization.md) - Instance sizing, scaling, and cost-saving strategies
- [Platforms](../_shared/references/platforms.md) - Platform-specific configuration and requirements
