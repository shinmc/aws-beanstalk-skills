---
name: eb-infra
description: Manages AWS infrastructure supporting Elastic Beanstalk — SSL certificates, custom domains, secrets, database monitoring, security auditing, CloudWatch alarms, and cost analysis. Use when user asks about SSL, HTTPS, certificates, custom domains, DNS, Route 53, secrets, API keys, parameter store, RDS, security groups, IAM roles, CloudWatch, monitoring, costs, or billing. For EB CLI operations use the dedicated skills.
compatibility: Requires AWS CLI with configured credentials. Some operations require specific IAM permissions (ACM, Route 53, Secrets Manager, RDS, CloudWatch, Cost Explorer).
license: MIT
allowed-tools:
  - Bash
metadata:
  author: shinmc
  version: 1.0.0
---

# AWS Infrastructure for Elastic Beanstalk

Manage AWS services that support Elastic Beanstalk environments — SSL certificates, custom domains, secrets, databases, security, monitoring, and costs.

## When to Use

- SSL/HTTPS certificate management
- Custom domain setup (Route 53)
- Secrets management (Secrets Manager, SSM Parameter Store)
- Database monitoring and snapshots (RDS)
- Security auditing (IAM, security groups)
- CloudWatch alarms and SNS notifications
- Cost analysis and optimization

## When NOT to Use

- EB CLI operations (deploy, status, logs, config) → use the dedicated skills
- Creating/managing environments → use `environment` skill
- Troubleshooting application issues → use `troubleshoot` skill
- Platform updates → use `maintenance` skill

## Prerequisites

**AWS CLI must be installed and configured:**
```bash
aws --version
aws configure
```

---

## SSL / HTTPS (ACM)

### List Certificates
```bash
aws acm list-certificates --output table
```

### Request Certificate (DNS Validation)
```bash
aws acm request-certificate \
  --domain-name example.com \
  --validation-method DNS \
  --subject-alternative-names "*.example.com" \
  --output json
```

### Check Certificate Status
```bash
aws acm describe-certificate --certificate-arn <arn> --output json
```

### Get DNS Validation Records
```bash
aws acm describe-certificate \
  --certificate-arn <arn> \
  --query 'Certificate.DomainValidationOptions[*].ResourceRecord' \
  --output table
```

Add these CNAME records to DNS (see Domains section below).

### Configure HTTPS on EB

After certificate is issued, edit via `eb config` (use `eb` skill):
```yaml
aws:elbv2:listener:443:
  ListenerEnabled: 'true'
  Protocol: HTTPS
  SSLCertificateArns: <certificate-arn>
```

### Delete Certificate
```bash
aws acm delete-certificate --certificate-arn <arn> --output json
```

Cannot delete if in use by a load balancer — remove from EB config first.

---

## Custom Domains (Route 53)

### List Hosted Zones
```bash
aws route53 list-hosted-zones --output table
```

### List DNS Records
```bash
aws route53 list-resource-record-sets --hosted-zone-id <zone-id> --output table
```

### Point Subdomain to EB (CNAME)
```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "app.example.com",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "<env-name>.us-east-1.elasticbeanstalk.com"}]
      }
    }]
  }'
```

### Point Root Domain to EB (ALIAS)
```bash
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "example.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "<eb-region-hosted-zone-id>",
          "DNSName": "<env-name>.us-east-1.elasticbeanstalk.com",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'
```

EB Hosted Zone IDs by region:
- us-east-1=Z117KPS5GTRQ2G, us-east-2=Z14LCN19Q5QHJI, us-west-1=Z1LQECGX5PH1X, us-west-2=Z38NKT9BP95V3O
- eu-west-1=Z2NYPWQ7DFZAZH, eu-west-2=Z1GKAAAUGATPF1, eu-west-3=Z5WN6GAABZTB7, eu-central-1=Z1FRNW7UH4DEZJ
- ap-southeast-1=Z16FZ9L249IFLT, ap-southeast-2=Z2PCDNR3VC2G1N, ap-northeast-1=Z1R25G3KIG2GBW, ap-northeast-2=Z3JE5OI70TWKCP
- ap-south-1=Z18NTBI3Y7N9TZ, ca-central-1=ZJFCZL7SSZB5I, sa-east-1=Z10X7K2B4QSOFV

For the full list, see [AWS Elastic Beanstalk endpoints](https://docs.aws.amazon.com/general/latest/gr/elasticbeanstalk.html).

### Check DNS Propagation
```bash
aws route53 get-change --id <change-id> --output json
```

### Delete DNS Record
Use `Action: "DELETE"` with exact same record values.

---

## Secrets (Secrets Manager & SSM)

### Secrets Manager

> **Security:** Avoid passing secret values directly on the command line — they are visible in shell history and process listings. Prefer `--secret-string file://secret.txt` where the file contains only the secret value.

```bash
# Create
aws secretsmanager create-secret \
  --name myapp/api-key \
  --secret-string file://secret.txt --output json

# Retrieve
aws secretsmanager get-secret-value --secret-id myapp/api-key --output json

# List
aws secretsmanager list-secrets --output table

# Update
aws secretsmanager update-secret \
  --secret-id myapp/api-key \
  --secret-string file://secret.txt --output json

# Rotate
aws secretsmanager rotate-secret --secret-id myapp/api-key --output json

# Delete (with 7-day recovery)
aws secretsmanager delete-secret \
  --secret-id myapp/api-key \
  --recovery-window-in-days 7 --output json
```

### SSM Parameter Store

> **Security:** Avoid passing secret values directly on the command line — they are visible in shell history and process listings. Prefer `--value file://secret.txt` where the file contains only the secret value.

```bash
# Create (encrypted)
aws ssm put-parameter \
  --name /myapp/prod/db-url \
  --value file://secret.txt \
  --type SecureString --output json

# Retrieve
aws ssm get-parameter --name /myapp/prod/db-url --with-decryption --output json

# List by path
aws ssm get-parameters-by-path --path /myapp/prod/ --with-decryption --output table

# Delete
aws ssm delete-parameter --name /myapp/prod/old-key --output json
```

### Reference Secrets in EB Environment Variables

EB natively resolves secrets at deployment time:
```bash
# Secrets Manager
eb setenv DB_PASS='{{resolve:secretsmanager:myapp/db-pass}}'

# SSM Parameter Store
eb setenv API_KEY='{{resolve:ssm-secure:/myapp/prod/api-key}}'
```

**Note:** `eb printenv` shows the reference syntax, not the resolved value. The app receives the actual value at runtime.

---

## Database (RDS)

**This section focuses on monitoring and snapshots. Do NOT create/delete databases via CLI — use AWS Console.**

### List RDS Instances
```bash
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine,Endpoint.Address,Endpoint.Port]' \
  --output table
```

### Get Connection Details
```bash
aws rds describe-db-instances \
  --db-instance-identifier <db-name> \
  --query 'DBInstances[0].Endpoint.[Address,Port]' \
  --output text
```

Compare with `eb printenv` to verify DATABASE_URL matches.

### Create Pre-Deploy Snapshot
```bash
aws rds create-db-snapshot \
  --db-instance-identifier <db-name> \
  --db-snapshot-identifier pre-deploy-$(date +%Y%m%d-%H%M) --output json
```

### List Snapshots
```bash
aws rds describe-db-snapshots \
  --db-instance-identifier <db-name> \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,Status,SnapshotCreateTime]' \
  --output table
```

### Check Pending Maintenance
```bash
aws rds describe-pending-maintenance-actions --output table
```

### View Database Logs
```bash
aws rds download-db-log-file-portion \
  --db-instance-identifier <db-name> \
  --log-file-name error/mysql-error-running.log --output text
```

---

## Security Audit

### Find EB Security Groups
```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*awseb*" \
  --query 'SecurityGroups[*].[GroupId,GroupName]' --output table
```

### Audit Inbound Rules
```bash
aws ec2 describe-security-groups \
  --group-ids <sg-id> \
  --query 'SecurityGroups[0].IpPermissions' --output json
```

### Flag Overly Permissive Rules (0.0.0.0/0)
```bash
aws ec2 describe-security-groups \
  --group-ids <sg-id> \
  --query 'SecurityGroups[0].IpPermissions[?IpRanges[?CidrIp==`0.0.0.0/0`]]' --output json
```

- Port 22 open to 0.0.0.0/0 → **Restrict to your IP**
- Port 80/443 open to 0.0.0.0/0 → OK for web-facing load balancers
- All ports open → **High risk, restrict immediately**

### Check EB IAM Roles
```bash
# Service role
aws iam get-role --role-name aws-elasticbeanstalk-service-role --output json
aws iam list-attached-role-policies --role-name aws-elasticbeanstalk-service-role --output table

# Instance profile
aws iam list-attached-role-policies --role-name aws-elasticbeanstalk-ec2-role --output table
```

### Find EB EC2 Instances
```bash
aws ec2 describe-instances \
  --filters "Name=tag:elasticbeanstalk:environment-name,Values=<env-name>" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' --output table
```

---

## Monitoring (CloudWatch Alarms)

### List EB Metrics
```bash
aws cloudwatch list-metrics \
  --namespace AWS/ElasticBeanstalk \
  --dimensions Name=EnvironmentName,Value=<env-name> --output table
```

Key metrics: `EnvironmentHealth`, `ApplicationRequests5xx`, `ApplicationLatencyP99`, `CPUUtilization`, `InstancesOk`

### Query Metrics (Last Hour)
```bash
# macOS:
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElasticBeanstalk \
  --metric-name CPUUtilization \
  --dimensions Name=EnvironmentName,Value=<env-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 --statistics Average Maximum --output table

# Linux:
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElasticBeanstalk \
  --metric-name CPUUtilization \
  --dimensions Name=EnvironmentName,Value=<env-name> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 --statistics Average Maximum --output table
```

### Create SNS Topic + Subscribe
```bash
aws sns create-topic --name eb-alerts --output json
aws sns subscribe --topic-arn <arn> --protocol email --notification-endpoint your@email.com
```

### Create Alarms
```bash
# High 5xx errors
aws cloudwatch put-metric-alarm \
  --alarm-name "<env>-high-5xx" \
  --namespace AWS/ElasticBeanstalk --metric-name ApplicationRequests5xx \
  --dimensions Name=EnvironmentName,Value=<env-name> \
  --statistic Sum --period 300 --evaluation-periods 2 --threshold 10 \
  --comparison-operator GreaterThanThreshold --alarm-actions <sns-arn>

# High CPU
aws cloudwatch put-metric-alarm \
  --alarm-name "<env>-high-cpu" \
  --namespace AWS/ElasticBeanstalk --metric-name CPUUtilization \
  --dimensions Name=EnvironmentName,Value=<env-name> \
  --statistic Average --period 300 --evaluation-periods 3 --threshold 80 \
  --comparison-operator GreaterThanThreshold --alarm-actions <sns-arn>

# Environment unhealthy
aws cloudwatch put-metric-alarm \
  --alarm-name "<env>-unhealthy" \
  --namespace AWS/ElasticBeanstalk --metric-name EnvironmentHealth \
  --dimensions Name=EnvironmentName,Value=<env-name> \
  --statistic Maximum --period 300 --evaluation-periods 1 --threshold 15 \
  --comparison-operator GreaterThanOrEqualToThreshold --alarm-actions <sns-arn>
```

### Manage Alarms
```bash
aws cloudwatch describe-alarms --alarm-name-prefix "<env>" --output table
aws cloudwatch delete-alarms --alarm-names "<alarm-name>"
```

---

## Cost Analysis

### Monthly Costs by Service
```bash
# macOS:
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -v-1m +%Y-%m-01),End=$(date -u +%Y-%m-01) \
  --granularity MONTHLY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE --output json

# Linux:
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '1 month ago' +%Y-%m-01),End=$(date -u +%Y-%m-01) \
  --granularity MONTHLY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE --output json
```

### Costs by EB Environment
```bash
# macOS:
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -v-1m +%Y-%m-01),End=$(date -u +%Y-%m-01) \
  --granularity MONTHLY --metrics UnblendedCost \
  --filter '{"Tags":{"Key":"elasticbeanstalk:environment-name","Values":["<env-name>"]}}' \
  --group-by Type=DIMENSION,Key=SERVICE --output json

# Linux:
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '1 month ago' +%Y-%m-01),End=$(date -u +%Y-%m-01) \
  --granularity MONTHLY --metrics UnblendedCost \
  --filter '{"Tags":{"Key":"elasticbeanstalk:environment-name","Values":["<env-name>"]}}' \
  --group-by Type=DIMENSION,Key=SERVICE --output json
```

### Cost Forecast
```bash
# macOS:
aws ce get-cost-forecast \
  --time-period Start=$(date -u +%Y-%m-%d),End=$(date -u -v+1m +%Y-%m-01) \
  --metric UNBLENDED_COST --granularity MONTHLY --output json

# Linux:
aws ce get-cost-forecast \
  --time-period Start=$(date -u +%Y-%m-%d),End=$(date -u -d '1 month' +%Y-%m-01) \
  --metric UNBLENDED_COST --granularity MONTHLY --output json
```

### Cost Optimization Tips
- CPU avg < 20% → downsize instance type
- Dev/test → use `--single` (no LB, saves ~$16/month)
- Enable Spot Instances for non-production
- Scale down during off-hours

---

## Composability

- **Deploy code**: Use `deploy` skill
- **Check status & health**: Use `status` skill
- **View logs**: Use `logs` skill
- **Change EB configuration**: Use `config` skill
- **Troubleshoot issues**: Use `troubleshoot` skill
- **Manage environments**: Use `environment` skill
- **Documentation & best practices**: Use `eb-docs` skill

## Additional Resources

- [Cost Optimization](../_shared/references/cost-optimization.md)
- [Configuration Options](../_shared/references/config-options.md)
