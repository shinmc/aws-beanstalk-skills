# AWS Elastic Beanstalk Cost Optimization Reference

## Cost Components

### Primary Costs
1. **EC2 Instances** - Largest cost component
2. **Load Balancers** - ALB/NLB/CLB charges
3. **Data Transfer** - Outbound bandwidth
4. **EBS Volumes** - Storage for instances
5. **RDS** - If using attached database

### Hidden Costs
- NAT Gateway (if in private subnet)
- CloudWatch Logs retention
- S3 for application versions
- Elastic IP addresses (if unused)

## Instance Right-Sizing

### Analyze Current Usage

```bash
# Get CPU metrics for last 7 days
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=EnvironmentName,Value=<env-name> \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 86400 \
  --statistics Average Maximum \
  --output table
```

### Right-Sizing Recommendations

| Avg CPU | Max CPU | Recommendation |
|---------|---------|----------------|
| < 10% | < 30% | Downsize instance |
| 10-40% | < 70% | Current size OK |
| 40-70% | < 90% | Monitor closely |
| > 70% | > 90% | Upgrade instance |

### Instance Type Comparison

> **Get current pricing:** https://aws.amazon.com/ec2/pricing/on-demand/
> Prices change frequently. Always verify before making decisions.

Common instance types for Elastic Beanstalk (us-east-1 reference):

| Type | vCPU | Memory | Use Case |
|------|------|--------|----------|
| t3.micro | 2 | 1 GB | Dev/test, very light workloads |
| t3.small | 2 | 2 GB | Light workloads, staging |
| t3.medium | 2 | 4 GB | Small production apps |
| t3.large | 2 | 8 GB | Medium production apps |
| t3.xlarge | 4 | 16 GB | Larger applications |
| m6i.large | 2 | 8 GB | Consistent CPU workloads |
| m6i.xlarge | 4 | 16 GB | Memory-intensive apps |
| c6i.large | 2 | 4 GB | CPU-intensive workloads |
| r6i.large | 2 | 16 GB | Memory-optimized |

### Get Current Pricing via CLI

```bash
# Get pricing for specific instance type
aws pricing get-products \
  --service-code AmazonEC2 \
  --filters \
    "Type=TERM_MATCH,Field=instanceType,Value=t3.medium" \
    "Type=TERM_MATCH,Field=location,Value=US East (N. Virginia)" \
    "Type=TERM_MATCH,Field=operatingSystem,Value=Linux" \
    "Type=TERM_MATCH,Field=tenancy,Value=Shared" \
    "Type=TERM_MATCH,Field=preInstalledSw,Value=NA" \
  --region us-east-1 \
  --output json
```

### AWS Pricing Calculator

Use the AWS Pricing Calculator for accurate estimates:
https://calculator.aws/#/addService/ElasticBeanstalk

### Burstable vs. Fixed

**Use t3 (burstable) when:**
- Variable workload
- CPU usage mostly < 20%
- Can tolerate occasional throttling
- Development/staging environments

**Use m5/c5 (fixed) when:**
- Consistent high CPU usage
- Latency-sensitive applications
- Production workloads
- t3 credits frequently depleted

## Auto Scaling Optimization

### Current Configuration Check
```bash
aws elasticbeanstalk describe-configuration-settings \
  --application-name <app> \
  --environment-name <env> \
  --output json | jq '.ConfigurationSettings[0].OptionSettings[] |
    select(.Namespace | contains("autoscaling"))'
```

### Optimized Scaling Settings

```bash
aws elasticbeanstalk update-environment \
  --environment-name <env> \
  --option-settings \
    Namespace=aws:autoscaling:asg,OptionName=MinSize,Value=1 \
    Namespace=aws:autoscaling:asg,OptionName=MaxSize,Value=4 \
    Namespace=aws:autoscaling:trigger,OptionName=MeasureName,Value=CPUUtilization \
    Namespace=aws:autoscaling:trigger,OptionName=LowerThreshold,Value=30 \
    Namespace=aws:autoscaling:trigger,OptionName=UpperThreshold,Value=70 \
    Namespace=aws:autoscaling:trigger,OptionName=BreachDuration,Value=5
```

### Scheduled Scaling

For predictable traffic patterns:
```bash
# Scale down at night (via ASG)
aws autoscaling put-scheduled-action \
  --auto-scaling-group-name <asg-name> \
  --scheduled-action-name scale-down-night \
  --recurrence "0 22 * * *" \
  --min-size 1 \
  --max-size 2

# Scale up in morning
aws autoscaling put-scheduled-action \
  --auto-scaling-group-name <asg-name> \
  --scheduled-action-name scale-up-morning \
  --recurrence "0 6 * * MON-FRI" \
  --min-size 2 \
  --max-size 10
```

## Reserved Instances & Savings Plans

### When to Use Reserved Instances

| Usage Pattern | Recommendation | Savings |
|---------------|----------------|---------|
| 24/7 stable | 1-year RI, All Upfront | ~40% |
| 24/7 stable | 3-year RI, All Upfront | ~60% |
| Variable | Savings Plans | ~30% |
| Occasional | On-Demand | 0% |

### Savings Plans Benefits
- More flexible than RIs
- Applies across instance families
- Covers Lambda and Fargate too
- Easier to manage

## Spot Instances

### When to Use Spot
- Development/test environments
- Batch processing
- Stateless web servers
- Fault-tolerant applications

### Not Recommended For
- Single-instance environments
- Stateful applications
- Time-critical workloads

### Implementation
Use mixed instance policy in ASG:
```json
{
  "LaunchTemplate": {...},
  "Overrides": [
    {"InstanceType": "t3.medium"},
    {"InstanceType": "t3.large"},
    {"InstanceType": "m5.large"}
  ],
  "InstancesDistribution": {
    "OnDemandBaseCapacity": 1,
    "OnDemandPercentageAboveBaseCapacity": 25,
    "SpotAllocationStrategy": "capacity-optimized"
  }
}
```

## Environment Optimization

### Single Instance for Dev/Test
```bash
aws elasticbeanstalk update-environment \
  --environment-name <env>-dev \
  --option-settings \
    Namespace=aws:elasticbeanstalk:environment,OptionName=EnvironmentType,Value=SingleInstance
```

Saves: Load balancer cost (~$16/month for ALB)

### Terminate Idle Environments

Check for idle environments:
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name <env> \
  --attribute-names ApplicationMetrics
# If RequestCount is 0 for extended periods, consider terminating
```

### Application Version Cleanup

```bash
aws elasticbeanstalk update-application-resource-lifecycle \
  --application-name <app> \
  --resource-lifecycle-config '{
    "VersionLifecycleConfig": {
      "MaxCountRule": {
        "Enabled": true,
        "MaxCount": 20,
        "DeleteSourceFromS3": true
      }
    }
  }'
```

## Load Balancer Optimization

### ALB vs. CLB Pricing

| Type | Base Cost | Per LCU/Hour | Best For |
|------|-----------|--------------|----------|
| CLB | $0.025/hr | N/A | Simple HTTP |
| ALB | $0.0225/hr | $0.008 | Modern apps |
| NLB | $0.0225/hr | $0.006 | TCP/UDP |

### Reduce LCU Usage
- Enable keep-alive connections
- Reduce request count with caching
- Optimize connection duration

## Data Transfer Optimization

### Reduce Outbound Costs
1. Use CloudFront for static assets
2. Enable gzip compression
3. Optimize image sizes
4. Use same-region for AWS services

### CloudFront Benefits
- Reduced origin requests
- Lower data transfer costs
- Better user experience
- DDoS protection included

## EBS Volume Optimization

### Volume Type Comparison

| Type | $/GB/month | IOPS | Use Case |
|------|------------|------|----------|
| gp3 | $0.08 | 3000 base | General purpose |
| gp2 | $0.10 | Varies | Legacy |
| io1 | $0.125 | Provisioned | High IOPS |

### Recommendations
- Use gp3 over gp2 (cheaper, better performance)
- Right-size volumes (don't over-provision)
- Delete unused snapshots

## Cost Monitoring

### Enable Cost Allocation Tags
```bash
aws elasticbeanstalk update-tags-for-resource \
  --resource-arn <env-arn> \
  --tags-to-add \
    Key=Environment,Value=production \
    Key=CostCenter,Value=engineering \
    Key=Project,Value=api
```

### Set Up Budget Alerts
```bash
aws budgets create-budget \
  --account-id <account> \
  --budget '{
    "BudgetName": "eb-monthly",
    "BudgetLimit": {"Amount": "500", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80
    },
    "Subscribers": [{
      "SubscriptionType": "EMAIL",
      "Address": "alerts@example.com"
    }]
  }]'
```

## Cost Optimization Checklist

- [ ] Right-size instances based on CPU/memory metrics
- [ ] Use t3 burstable for variable workloads
- [ ] Configure auto-scaling with appropriate thresholds
- [ ] Use scheduled scaling for predictable patterns
- [ ] Consider Reserved Instances for stable workloads
- [ ] Terminate unused environments
- [ ] Use Single Instance for dev/test
- [ ] Clean up old application versions
- [ ] Enable gzip compression
- [ ] Use CloudFront for static assets
- [ ] Switch to gp3 EBS volumes
- [ ] Set up cost allocation tags
- [ ] Configure budget alerts
