---
name: config
description: This skill should be used when the user asks "show config", "what's configured", "change settings", "environment variables", "scaling settings", or wants to read/modify Elastic Beanstalk configuration. For environment creation, use environment skill.
argument-hint: "[env-name]"
allowed-tools: Bash(aws elasticbeanstalk:*), Bash(scripts/eb-api.sh:*)
---

# AWS Elastic Beanstalk Configuration

Query, validate, and update Elastic Beanstalk environment configuration.

## When to Use

- User asks "what's the config", "show settings"
- User wants to add/change environment variables
- User asks about scaling, instance type, load balancer settings
- User says "validate my config", "update settings"

## When NOT to Use

- For creating new environments → use `environment` skill
- For deploying new versions → use `deploy` skill
- For health status → use `health` skill

## Read Current Configuration

Get all configuration settings:
```bash
aws elasticbeanstalk describe-configuration-settings \
  --application-name <app-name> \
  --environment-name <env-name> \
  --output json
```

## Configuration Namespaces

Key namespaces for common settings:

### Environment Variables
```
aws:elasticbeanstalk:application:environment
```

### Auto Scaling
```
aws:autoscaling:asg
- MinSize, MaxSize, Cooldown

aws:autoscaling:launchconfiguration
- InstanceType, EC2KeyName, IamInstanceProfile

aws:autoscaling:trigger
- MeasureName, LowerThreshold, UpperThreshold
```

### Load Balancer
```
aws:elb:loadbalancer
- CrossZone, SecurityGroups

aws:elb:listener
- ListenerProtocol, InstanceProtocol, InstancePort

aws:elasticbeanstalk:environment:process:default
- HealthCheckPath, HealthCheckInterval
```

### Environment
```
aws:elasticbeanstalk:environment
- EnvironmentType (SingleInstance, LoadBalanced)
- ServiceRole

aws:elasticbeanstalk:healthreporting:system
- SystemType (enhanced, basic)
```

## View Available Options

List all configurable options for a platform:
```bash
aws elasticbeanstalk describe-configuration-options \
  --environment-name <env-name> \
  --output json
```

Filter by namespace:
```bash
aws elasticbeanstalk describe-configuration-options \
  --environment-name <env-name> \
  --options Namespace=aws:autoscaling:asg \
  --output json
```

## Update Configuration

### Single Option
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:elasticbeanstalk:application:environment,OptionName=NODE_ENV,Value=production \
  --output json
```

### Multiple Options
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:autoscaling:asg,OptionName=MinSize,Value=2 \
    Namespace=aws:autoscaling:asg,OptionName=MaxSize,Value=10 \
    Namespace=aws:autoscaling:launchconfiguration,OptionName=InstanceType,Value=t3.medium \
  --output json
```

### Using JSON File
```bash
# Create options.json
cat > options.json << 'EOF'
[
  {
    "Namespace": "aws:autoscaling:asg",
    "OptionName": "MinSize",
    "Value": "2"
  },
  {
    "Namespace": "aws:autoscaling:asg",
    "OptionName": "MaxSize",
    "Value": "10"
  }
]
EOF

aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings file://options.json \
  --output json
```

## Validate Configuration

Before applying changes:
```bash
aws elasticbeanstalk validate-configuration-settings \
  --application-name <app-name> \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:autoscaling:asg,OptionName=MinSize,Value=2 \
  --output json
```

Response shows validation status:
```json
{
  "Messages": [
    {
      "Message": "Configuration is valid",
      "Severity": "info"
    }
  ]
}
```

## Configuration Templates

### Create Template from Environment
```bash
aws elasticbeanstalk create-configuration-template \
  --application-name <app-name> \
  --template-name production-template \
  --environment-id <env-id> \
  --output json
```

### Create Template with Settings
```bash
aws elasticbeanstalk create-configuration-template \
  --application-name <app-name> \
  --template-name my-template \
  --solution-stack-name "64bit Amazon Linux 2023 v6.0.0 running Node.js 18" \
  --option-settings file://options.json \
  --output json
```

### Apply Template
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --template-name production-template \
  --output json
```

## Common Configuration Tasks

### Scale Instances (eb scale equivalent)

Scale to a specific number of instances:
```bash
# Scale to exactly N instances (set both min and max)
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:autoscaling:asg,OptionName=MinSize,Value=<N> \
    Namespace=aws:autoscaling:asg,OptionName=MaxSize,Value=<N> \
  --output json
```

Scale with range (allow auto-scaling):
```bash
# Set scaling range
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:autoscaling:asg,OptionName=MinSize,Value=2 \
    Namespace=aws:autoscaling:asg,OptionName=MaxSize,Value=10 \
  --output json
```

Check current scaling:
```bash
aws elasticbeanstalk describe-configuration-settings \
  --application-name <app-name> \
  --environment-name <env-name> \
  --output json | jq '.ConfigurationSettings[0].OptionSettings[] | select(.Namespace == "aws:autoscaling:asg")'
```

### Configure Auto-Scaling Triggers
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:autoscaling:trigger,OptionName=MeasureName,Value=CPUUtilization \
    Namespace=aws:autoscaling:trigger,OptionName=Unit,Value=Percent \
    Namespace=aws:autoscaling:trigger,OptionName=LowerThreshold,Value=20 \
    Namespace=aws:autoscaling:trigger,OptionName=UpperThreshold,Value=80 \
    Namespace=aws:autoscaling:trigger,OptionName=BreachDuration,Value=5 \
  --output json
```

### Set Environment Variables
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:elasticbeanstalk:application:environment,OptionName=DATABASE_URL,Value=postgres://... \
    Namespace=aws:elasticbeanstalk:application:environment,OptionName=API_KEY,Value=secret123 \
  --output json
```

### Change Instance Type
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:autoscaling:launchconfiguration,OptionName=InstanceType,Value=t3.large \
  --output json
```

### Enable Enhanced Health
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:elasticbeanstalk:healthreporting:system,OptionName=SystemType,Value=enhanced \
  --output json
```

### Configure Health Check
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:elasticbeanstalk:environment:process:default,OptionName=HealthCheckPath,Value=/health \
    Namespace=aws:elasticbeanstalk:environment:process:default,OptionName=HealthCheckInterval,Value=15 \
  --output json
```

## Platform-Specific Settings

### Node.js
```
aws:elasticbeanstalk:container:nodejs
- NodeVersion, NodeCommand, ProxyServer
```

### Python
```
aws:elasticbeanstalk:container:python
- WSGIPath, NumProcesses, NumThreads
```

### Docker
```
aws:elasticbeanstalk:environment:proxy
- ProxyServer (nginx, none)
```

## Presenting Configuration

When showing config:
- Group by category (scaling, networking, environment vars)
- Highlight non-default values
- Show current vs. pending changes

Example output:
```
=== Environment: my-app-prod ===

Scaling:
  Instance Type: t3.medium
  Min Instances: 2
  Max Instances: 10

Environment Variables:
  NODE_ENV: production
  DATABASE_URL: ********
  API_KEY: ********

Health Check:
  Path: /health
  Interval: 15 seconds

Load Balancer:
  Type: application
  Cross-Zone: enabled
```

## Error Handling

### Invalid Option
```
Option not valid for this platform. Check available options:
aws elasticbeanstalk describe-configuration-options --environment-name <env>
```

### Validation Error
```
Configuration validation failed:
- MinSize cannot be greater than MaxSize
```

### Update In Progress
```
Cannot update - environment update already in progress.
Wait for current update to complete.
```

## Composability

- **Check current status**: Use `status` skill
- **Deploy changes**: Use `deploy` skill
- **Analyze issues**: Use `troubleshoot` skill
- **View events after update**: Use `logs` skill

## Additional Resources

For detailed reference information, see the shared reference files:

- [Configuration Options](../_shared/references/config-options.md) - All available configuration namespaces and options
- [Health States](../_shared/references/health-states.md) - Health colors, statuses, and thresholds
- [Cost Optimization](../_shared/references/cost-optimization.md) - Instance sizing, scaling, and cost-saving strategies
- [Platforms](../_shared/references/platforms.md) - Platform-specific configuration and requirements
