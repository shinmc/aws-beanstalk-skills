---
name: troubleshoot
description: This skill should be used when the user asks to diagnose issues, fix problems, "why is it failing", "what's wrong", optimize performance, or reduce costs. Combines health, logs, and config analysis to provide recommendations.
argument-hint: "[env-name]"
allowed-tools: Bash(aws elasticbeanstalk:*), Bash(aws cloudwatch:*), Bash(curl:*), Bash(scripts/eb-api.sh:*)
---

# AWS Elastic Beanstalk Troubleshooting

Diagnose issues, suggest fixes, and optimize Elastic Beanstalk environments.

**This is the aggregator skill** - it combines data from health, logs, config, and metrics to provide comprehensive diagnosis and recommendations.

## When to Use

- User asks "why is it failing", "what's wrong"
- User wants to diagnose health issues
- User asks about performance optimization
- User wants cost optimization recommendations
- User says "fix this", "help me debug"
- User wants a comprehensive analysis (not just logs OR health)
- User needs recommendations with actionable fixes

## Diagnostic Workflow

### Step 1: Gather Environment Info
```bash
# Get environment status and health
aws elasticbeanstalk describe-environments \
  --environment-names <env-name> \
  --output json

# Get detailed health
aws elasticbeanstalk describe-environment-health \
  --environment-name <env-name> \
  --attribute-names All \
  --output json

# Get instance health
aws elasticbeanstalk describe-instances-health \
  --environment-name <env-name> \
  --attribute-names All \
  --output json
```

### Step 2: Check Recent Events
```bash
aws elasticbeanstalk describe-events \
  --environment-name <env-name> \
  --severity ERROR \
  --max-records 20 \
  --output json
```

### Step 3: Get Logs
```bash
# Request logs
aws elasticbeanstalk request-environment-info \
  --environment-name <env-name> \
  --info-type tail

# Wait and retrieve
sleep 15
aws elasticbeanstalk retrieve-environment-info \
  --environment-name <env-name> \
  --info-type tail \
  --output json
```

### Step 4: Check Configuration
```bash
aws elasticbeanstalk describe-configuration-settings \
  --application-name <app-name> \
  --environment-name <env-name> \
  --output json
```

## Common Issues & Fixes

### Health Check Failures

**Symptoms:**
- Red/Yellow health
- Instances failing health checks
- 5xx errors

**Diagnosis:**
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name <env-name> \
  --attribute-names Causes InstancesHealth \
  --output json
```

**Common Fixes:**
1. **Health check path wrong**
   ```bash
   aws elasticbeanstalk update-environment \
     --environment-name <env-name> \
     --option-settings Namespace=aws:elasticbeanstalk:environment:process:default,OptionName=HealthCheckPath,Value=/health
   ```

2. **App taking too long to start**
   - Increase health check interval
   - Add readiness endpoint

3. **Port mismatch**
   - Ensure app listens on correct port (default: 5000 for Node.js, 8080 for others)

### Deployment Failures

**Symptoms:**
- Environment stuck in "Updating"
- Deployment rollback

**Diagnosis:**
```bash
aws elasticbeanstalk describe-events \
  --environment-name <env-name> \
  --severity ERROR \
  --max-records 10 \
  --output json
```

**Common Fixes:**
1. **Build command failed**
   - Check package.json/requirements.txt
   - Verify build dependencies

2. **Application crash on start**
   - Check start command
   - Verify environment variables

3. **Insufficient permissions**
   - Check IAM instance profile
   - Verify S3/RDS access

### High Latency

**Symptoms:**
- Yellow health due to latency
- Slow response times

**Diagnosis:**
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name <env-name> \
  --attribute-names ApplicationMetrics \
  --output json
```

**Common Fixes:**
1. **Increase instance size**
   ```bash
   aws elasticbeanstalk update-environment \
     --environment-name <env-name> \
     --option-settings Namespace=aws:autoscaling:launchconfiguration,OptionName=InstanceType,Value=t3.large
   ```

2. **Add more instances**
   ```bash
   aws elasticbeanstalk update-environment \
     --environment-name <env-name> \
     --option-settings Namespace=aws:autoscaling:asg,OptionName=MinSize,Value=3
   ```

3. **Enable caching**
   - Add ElastiCache
   - Implement application-level caching

### Out of Memory

**Symptoms:**
- Instances terminated unexpectedly
- OOM errors in logs

**Fixes:**
1. Upgrade to larger instance type
2. Optimize application memory usage
3. Increase swap space

### Database Connection Issues

**Symptoms:**
- "Connection refused" or timeout errors
- Intermittent failures

**Checks:**
1. Security group allows EB → RDS
2. DATABASE_URL is correct
3. RDS is running and accessible

## Cost Optimization

### Right-Size Instances

**Check current utilization:**
```bash
# Linux
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=<asg-name> \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 86400 \
  --statistics Average Maximum \
  --output json

# macOS
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=<asg-name> \
  --start-time $(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 86400 \
  --statistics Average Maximum \
  --output json
```

**Recommendations:**
- CPU avg < 20%: Consider smaller instance
- CPU avg > 70%: Consider larger instance
- CPU spiky: Consider burstable (t3) instances

### Optimize Scaling

**Check for over-provisioning:**
```bash
aws elasticbeanstalk describe-configuration-settings \
  --application-name <app-name> \
  --environment-name <env-name> \
  --output json | jq '.ConfigurationSettings[0].OptionSettings[] | select(.Namespace == "aws:autoscaling:asg")'
```

**Cost-saving options:**
1. Lower MinSize during off-hours
2. Use spot instances for non-critical workloads
3. Implement scheduled scaling

### Reserved Instances

For stable workloads running 24/7:
- Calculate baseline instance count
- Consider reserved instances (up to 72% savings)
- Use Savings Plans for flexibility

### Idle Environment Detection

Check if environment has traffic:
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name <env-name> \
  --attribute-names ApplicationMetrics \
  --output json
```

If `RequestCount` is 0 for extended periods:
- Consider terminating unused environments
- Implement auto-shutdown for dev/staging

## Performance Analysis

### Identify Bottlenecks

```bash
# Check instance metrics
aws elasticbeanstalk describe-instances-health \
  --environment-name <env-name> \
  --attribute-names All \
  --output json
```

**Look for:**
- High CPU on specific instances
- Uneven load distribution
- Memory pressure

### Recommendations

**High CPU:**
- Profile application code
- Consider async processing
- Add caching layer

**High Memory:**
- Check for memory leaks
- Optimize data structures
- Increase instance size

**High Latency:**
- Add CDN for static assets
- Optimize database queries
- Implement caching

## Presenting Diagnosis

Example output:
```
=== Troubleshooting: my-app-prod ===

Health: Yellow (Warning)

Issues Found:
  1. High CPU utilization (avg 78%)
     - Instance i-abc123: 92% CPU
     - Recommendation: Scale up to t3.large or add instances

  2. Health check failures (2 in last hour)
     - Cause: Response time > 5s threshold
     - Recommendation: Optimize /health endpoint or increase timeout

  3. P99 latency elevated (800ms)
     - Normal: < 200ms
     - Recommendation: Check database queries, add caching

Cost Optimization:
  - Current monthly cost: ~$150
  - MinSize=3 but traffic suggests 2 sufficient during off-hours
  - Recommendation: Implement scheduled scaling

Suggested Actions:
  1. Scale instance type: t3.medium → t3.large
  2. Add scheduled scaling for off-hours
  3. Review slow database queries
```

## Error Handling

### Cannot Access CloudWatch
```
CloudWatch metrics not accessible. Ensure IAM role has cloudwatch:GetMetricStatistics permission.
```

### No Metrics Available
```
No metrics found. Environment may be new or enhanced health not enabled.
```

## Composability

- **Get detailed logs**: Use `logs` skill
- **Check health metrics**: Use `health` skill
- **Apply config fixes**: Use `config` skill
- **Create new environment**: Use `environment` skill

## Additional Resources

For detailed reference information, see the shared reference files:

- [Configuration Options](../_shared/references/config-options.md) - All available configuration namespaces and options
- [Health States](../_shared/references/health-states.md) - Health colors, statuses, and thresholds
- [Cost Optimization](../_shared/references/cost-optimization.md) - Instance sizing, scaling, and cost-saving strategies
- [Platforms](../_shared/references/platforms.md) - Platform-specific configuration and requirements
