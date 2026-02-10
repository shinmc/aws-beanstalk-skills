---
name: eb-infra
description: This skill should be used when the user asks about SSL, HTTPS, certificates, custom domains, DNS, Route 53, secrets, API keys, parameter store, database, RDS, security groups, IAM roles, CloudWatch alarms, monitoring, costs, billing, or any AWS infrastructure service supporting Elastic Beanstalk environments. For EB CLI operations use the dedicated skills (deploy, status, logs, config, troubleshoot, environment, app, maintenance).
---

# AWS Infrastructure for Elastic Beanstalk

Manage AWS services that support Elastic Beanstalk environments — SSL certificates, custom domains, secrets, databases, security, monitoring, and costs.

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
aws acm delete-certificate --certificate-arn <arn>
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

EB Hosted Zone IDs: us-east-1=Z117KPS5GTRQ2G, us-west-2=Z38NKT9BP95V3O, eu-west-1=Z2NYPWQ7DFZAZH

### Check DNS Propagation
```bash
aws route53 get-change --id <change-id> --output json
```

### Delete DNS Record
Use `Action: "DELETE"` with exact same record values.

---

## Secrets (Secrets Manager & SSM)

### Secrets Manager

```bash
# Create
aws secretsmanager create-secret \
  --name myapp/api-key \
  --secret-string "sk-abc123" --output json

# Retrieve
aws secretsmanager get-secret-value --secret-id myapp/api-key --output json

# List
aws secretsmanager list-secrets --output table

# Update
aws secretsmanager update-secret \
  --secret-id myapp/api-key \
  --secret-string "sk-new-key" --output json

# Rotate
aws secretsmanager rotate-secret --secret-id myapp/api-key --output json

# Delete (with 7-day recovery)
aws secretsmanager delete-secret \
  --secret-id myapp/api-key \
  --recovery-window-in-days 7 --output json
```

### SSM Parameter Store

```bash
# Create (encrypted)
aws ssm put-parameter \
  --name /myapp/prod/db-url \
  --value "postgres://..." \
  --type SecureString --output json

# Retrieve
aws ssm get-parameter --name /myapp/prod/db-url --with-decryption --output json

# List by path
aws ssm get-parameters-by-path --path /myapp/prod/ --with-decryption --output table

# Delete
aws ssm delete-parameter --name /myapp/prod/old-key
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
