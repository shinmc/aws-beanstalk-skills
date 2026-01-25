---
name: health
description: This skill should be used when the user asks about environment health, instance health, "is it healthy", "why is it yellow/red", CPU/memory usage, or latency metrics. For basic status, use status skill. For troubleshooting, use troubleshoot skill.
argument-hint: "[env-name]"
allowed-tools: Bash(aws elasticbeanstalk:*), Bash(scripts/eb-api.sh:*)
---

# AWS Elastic Beanstalk Health Monitoring

Check detailed health status of Elastic Beanstalk environments and instances.

## When to Use

- User asks "is it healthy", "why is health red/yellow"
- User wants CPU, memory, latency metrics
- User asks about individual instance health
- User says "check health", "health status"

## When NOT to Use

- For basic environment status → use `status` skill
- For logs and events → use `logs` skill
- For diagnosing and fixing issues → use `troubleshoot` skill
- For comprehensive "what's wrong" analysis → use `troubleshoot` skill (it combines health + logs + config)

## Environment Health

Get overall environment health with metrics:
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name <env-name> \
  --attribute-names All \
  --output json
```

Specific attributes:
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name <env-name> \
  --attribute-names Status HealthStatus Color Causes ApplicationMetrics InstancesHealth \
  --output json
```

## Health Colors

| Color | Meaning |
|-------|---------|
| **Green** | Environment is healthy and operating normally |
| **Yellow** | Warning - some issues but still operational |
| **Red** | Degraded - significant issues affecting operation |
| **Grey** | Unknown - health status cannot be determined |

## Health Status Values

| Status | Description |
|--------|-------------|
| `Ok` | All health checks passing |
| `Warning` | Minor issues detected |
| `Degraded` | Significant issues, may affect users |
| `Severe` | Critical issues, service likely impaired |
| `Info` | Informational (during updates) |
| `Pending` | Health status being evaluated |
| `Unknown` | Cannot determine health |

## Instance Health

Get per-instance health details:
```bash
aws elasticbeanstalk describe-instances-health \
  --environment-name <env-name> \
  --attribute-names All \
  --output json
```

Response includes per-instance:
- Instance ID and availability zone
- Health status and color
- CPU utilization
- Load average
- Deployment status
- System status

## Application Metrics

From `describe-environment-health`:
```json
{
  "ApplicationMetrics": {
    "Duration": 10,
    "RequestCount": 1000,
    "StatusCodes": {
      "Status2xx": 980,
      "Status3xx": 10,
      "Status4xx": 8,
      "Status5xx": 2
    },
    "Latency": {
      "P999": 0.5,
      "P99": 0.2,
      "P95": 0.1,
      "P90": 0.08,
      "P85": 0.07,
      "P75": 0.06,
      "P50": 0.04,
      "P10": 0.02
    }
  }
}
```

## Interpreting Health

### Green Environment
```
Health: Green (Ok)
All instances healthy, normal response times
```

### Yellow Environment - Common Causes
- Deployment in progress
- Some instances unhealthy
- High latency (above threshold)
- Recent errors but recovering

### Red Environment - Common Causes
- Multiple instances failing health checks
- Application crashing repeatedly
- High error rate (5xx responses)
- Deployment failed

### Grey Environment - Common Causes
- Enhanced health not enabled
- Environment launching/terminating
- No data available yet

## Health Check Configuration

View health check settings:
```bash
aws elasticbeanstalk describe-configuration-settings \
  --application-name <app-name> \
  --environment-name <env-name> \
  --output json | jq '.ConfigurationSettings[0].OptionSettings[] | select(.Namespace | contains("health"))'
```

## Enable Enhanced Health Reporting

Enhanced health provides more metrics:
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --option-settings \
    Namespace=aws:elasticbeanstalk:healthreporting:system,OptionName=SystemType,Value=enhanced \
  --output json
```

## Presenting Health

Example output format:
```
=== Environment Health: my-app-prod ===

Overall: Green (Ok)
Last Updated: 2024-01-15 10:30:00

Instances: 3/3 healthy
  i-abc123 (us-east-1a): Ok - CPU 15%, Load 0.5
  i-def456 (us-east-1b): Ok - CPU 20%, Load 0.8
  i-ghi789 (us-east-1c): Ok - CPU 12%, Load 0.3

Requests (last 10s):
  Total: 1,000
  2xx: 980 (98%)
  4xx: 18 (1.8%)
  5xx: 2 (0.2%)

Latency:
  P50: 40ms
  P95: 100ms
  P99: 200ms

No health issues detected.
```

### Yellow/Red Alert Format
```
=== Environment Health: my-app-prod ===

Overall: Yellow (Warning)
Last Updated: 2024-01-15 10:30:00

Causes:
  - 1 instance has degraded health
  - P99 latency above threshold (800ms > 500ms)

Instances: 2/3 healthy
  i-abc123 (us-east-1a): Ok - CPU 15%
  i-def456 (us-east-1b): Warning - CPU 85%, Load 4.2
  i-ghi789 (us-east-1c): Ok - CPU 12%

Recommendations:
  1. Check i-def456 for high CPU usage
  2. Consider scaling up or out
  3. Review recent deployments
```

## Error Handling

### Enhanced Health Not Enabled
```
Detailed health metrics require enhanced health reporting.
Enable with:
aws elasticbeanstalk update-environment \
  --environment-name <env> \
  --option-settings Namespace=aws:elasticbeanstalk:healthreporting:system,OptionName=SystemType,Value=enhanced
```

### No Instances
```
Environment has no running instances. Check:
- Environment is not terminated
- Auto scaling min size is at least 1
```

### Environment Updating
```
Health status may be inaccurate during updates.
Current update status: Updating...
```

## Composability

- **View logs for unhealthy instances**: Use `logs` skill
- **Diagnose and fix issues**: Use `troubleshoot` skill
- **Update configuration**: Use `config` skill
- **Check basic status**: Use `status` skill

## Additional Resources

For detailed reference information, see the shared reference files:

- [Configuration Options](../_shared/references/config-options.md) - All available configuration namespaces and options
- [Health States](../_shared/references/health-states.md) - Health colors, statuses, and thresholds
- [Cost Optimization](../_shared/references/cost-optimization.md) - Instance sizing, scaling, and cost-saving strategies
- [Platforms](../_shared/references/platforms.md) - Platform-specific configuration and requirements
