---
name: environment
description: This skill should be used when the user wants to create, terminate, rebuild, or swap environments, "create beanstalk environment", "new eb environment", "delete environment", perform blue/green deployments, or manage environment lifecycle. For configuration changes, use config skill. For deployments, use deploy skill.
argument-hint: "[env-name]"
disable-model-invocation: true
allowed-tools: Bash(aws elasticbeanstalk:*), Bash(scripts/eb-api.sh:*)
---

# AWS Elastic Beanstalk Environment Management

Create, terminate, rebuild, and manage Elastic Beanstalk environment lifecycle.

## When to Use

- User wants to create a new environment
- User says "terminate environment", "delete environment"
- User asks for blue/green deployment
- User wants to rebuild or clone an environment
- User says "swap URLs", "switch environments"

## When NOT to Use

- For deploying versions → use `deploy` skill
- For configuration changes → use `config` skill
- For health status → use `health` skill

## IAM Prerequisites

Before creating an environment, you need two IAM resources:

### 1. Service Role
The role Elastic Beanstalk uses to manage AWS resources on your behalf.

**Check if it exists:**
```bash
aws iam get-role --role-name aws-elasticbeanstalk-service-role --output json 2>/dev/null && echo "Service role exists" || echo "Service role NOT found"
```

**Create if missing:**
```bash
# Create the service role
aws iam create-role \
  --role-name aws-elasticbeanstalk-service-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "elasticbeanstalk.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' \
  --output json

# Attach required policies
aws iam attach-role-policy \
  --role-name aws-elasticbeanstalk-service-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth

aws iam attach-role-policy \
  --role-name aws-elasticbeanstalk-service-role \
  --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy
```

### 2. EC2 Instance Profile
The role attached to EC2 instances running your application.

**Check if it exists:**
```bash
aws iam get-instance-profile --instance-profile-name aws-elasticbeanstalk-ec2-role --output json 2>/dev/null && echo "Instance profile exists" || echo "Instance profile NOT found"
```

**Create if missing:**
```bash
# Create the IAM role
aws iam create-role \
  --role-name aws-elasticbeanstalk-ec2-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' \
  --output json

# Attach required policies
aws iam attach-role-policy \
  --role-name aws-elasticbeanstalk-ec2-role \
  --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier

aws iam attach-role-policy \
  --role-name aws-elasticbeanstalk-ec2-role \
  --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier

aws iam attach-role-policy \
  --role-name aws-elasticbeanstalk-ec2-role \
  --policy-arn arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker

# Create instance profile and add role
aws iam create-instance-profile \
  --instance-profile-name aws-elasticbeanstalk-ec2-role \
  --output json

aws iam add-role-to-instance-profile \
  --instance-profile-name aws-elasticbeanstalk-ec2-role \
  --role-name aws-elasticbeanstalk-ec2-role
```

### Specifying Roles During Environment Creation
```bash
# First, set $PLATFORM (see "Get Latest Platform Version" in Create Environment section)
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <env-name> \
  --solution-stack-name "$PLATFORM" \
  --option-settings \
    Namespace=aws:elasticbeanstalk:environment,OptionName=ServiceRole,Value=aws-elasticbeanstalk-service-role \
    Namespace=aws:elasticbeanstalk:environment,OptionName=LoadBalancerType,Value=application \
    Namespace=aws:autoscaling:launchconfiguration,OptionName=IamInstanceProfile,Value=aws-elasticbeanstalk-ec2-role \
  --output json
```

## Destructive Operations Warning

**Before running terminate, rebuild, or force operations:**

1. **Verify the environment name** - Double-check you're targeting the correct environment
2. **Check for active traffic** - Use `health` skill to verify no users are affected
3. **Confirm with user** - Always ask for explicit confirmation before destructive actions
4. **Consider backups** - Ensure configuration is saved if needed

Commands requiring extra caution:
- `terminate-environment` - Permanently deletes the environment
- `terminate-environment --force-terminate` - Skips cleanup, may leave orphaned resources
- `rebuild-environment` - Causes downtime, recreates all instances

## Create Environment

### Get Latest Platform Version (Run First)

Always fetch the latest platform version before creating an environment:
```bash
PLATFORM=$(aws elasticbeanstalk list-available-solution-stacks --query "SolutionStacks[?contains(@, '<platform>')] | [0]" --output text)
echo $PLATFORM
```

Replace `<platform>` with your target:
- Node.js: `Node.js 20`, `Node.js 22`, `Node.js 24`
- Python: `Python 3.9`, `Python 3.11`, `Python 3.12`, `Python 3.13`
- Docker: `Docker') && contains(@, 'Amazon Linux 2023`
- Java: `Corretto 8`, `Corretto 11`, `Corretto 17`, `Corretto 21`

> **Note:** All commands below assume `$PLATFORM` is set.

### Basic Creation
```bash
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <env-name> \
  --solution-stack-name "$PLATFORM" \
  --output json
```

### With Version
```bash
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <env-name> \
  --version-label "v1.0.0" \
  --solution-stack-name "$PLATFORM" \
  --output json
```

### With Configuration Template
```bash
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <env-name> \
  --template-name production-template \
  --output json
```

### With Custom Options
```bash
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <env-name> \
  --solution-stack-name "$PLATFORM" \
  --option-settings \
    Namespace=aws:elasticbeanstalk:environment,OptionName=ServiceRole,Value=aws-elasticbeanstalk-service-role \
    Namespace=aws:elasticbeanstalk:environment,OptionName=LoadBalancerType,Value=application \
    Namespace=aws:autoscaling:launchconfiguration,OptionName=IamInstanceProfile,Value=aws-elasticbeanstalk-ec2-role \
    Namespace=aws:autoscaling:launchconfiguration,OptionName=InstanceType,Value=t3.medium \
    Namespace=aws:autoscaling:asg,OptionName=MinSize,Value=2 \
    Namespace=aws:autoscaling:asg,OptionName=MaxSize,Value=10 \
  --output json
```

### With CNAME Prefix
```bash
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name my-app-prod \
  --cname-prefix my-app-prod \
  --solution-stack-name "$PLATFORM" \
  --output json
```

## Check CNAME Availability

Before creating with custom CNAME:
```bash
aws elasticbeanstalk check-dns-availability \
  --cname-prefix <desired-prefix> \
  --output json
```

## List Solution Stacks

Find available platforms:
```bash
# List all platforms
aws elasticbeanstalk list-available-solution-stacks --output json | jq '.SolutionStacks[]'

# Filter by keyword
aws elasticbeanstalk list-available-solution-stacks --output json | jq '.SolutionStacks[]' | grep -i <platform>

# Get latest version
aws elasticbeanstalk list-available-solution-stacks --query "SolutionStacks[?contains(@, '<platform>')] | [0]" --output text
```

## Terminate Environment

```bash
aws elasticbeanstalk terminate-environment \
  --environment-name <env-name> \
  --output json
```

### Force Terminate (skip resource cleanup)
```bash
aws elasticbeanstalk terminate-environment \
  --environment-name <env-name> \
  --force-terminate \
  --output json
```

## Rebuild Environment

Recreate environment with same configuration:
```bash
aws elasticbeanstalk rebuild-environment \
  --environment-name <env-name> \
  --output json
```

Use when:
- Environment is corrupted
- Need fresh instances
- Infrastructure issues

## Blue/Green Deployment

### Step 1: Create Clone (Green)
```bash
# Create new environment with different CNAME
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <app>-green \
  --version-label "v2.0.0" \
  --cname-prefix <app>-green \
  --solution-stack-name "..." \
  --output json
```

### Step 2: Wait for Ready
```bash
aws elasticbeanstalk describe-environments \
  --environment-names <app>-green \
  --query 'Environments[0].Status' \
  --output text
```

### Step 3: Test Green Environment
Verify at: `<app>-green.elasticbeanstalk.com`

### Step 4: Swap CNAMEs
```bash
aws elasticbeanstalk swap-environment-cnames \
  --source-environment-name <app>-blue \
  --destination-environment-name <app>-green \
  --output json
```

### Step 5: Terminate Old Environment (Optional)
```bash
aws elasticbeanstalk terminate-environment \
  --environment-name <app>-blue \
  --output json
```

## Abort Update

Cancel an in-progress environment update:
```bash
aws elasticbeanstalk abort-environment-update \
  --environment-name <env-name> \
  --output json
```

Use when:
- Deployment is failing
- Need to stop and investigate
- Wrong version deployed

## Environment Tiers

### Web Server (default)
For HTTP applications:
```bash
--tier Name=WebServer,Type=Standard,Version="1.0"
```

### Worker
For background processing:
```bash
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <app>-worker \
  --tier Name=Worker,Type=SQS/HTTP,Version="1.0" \
  --solution-stack-name "..." \
  --output json
```

## Restore Terminated Environment

Restore a recently terminated environment (within retention period).

### List Terminated Environments
```bash
aws elasticbeanstalk describe-environments \
  --include-deleted \
  --included-deleted-back-to $(date -u -v-14d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '14 days ago' +%Y-%m-%dT%H:%M:%SZ) \
  --query 'Environments[?Status==`Terminated`].{Name:EnvironmentName,ID:EnvironmentId,Terminated:DateUpdated,App:ApplicationName}' \
  --output table
```

### Restore Environment
```bash
aws elasticbeanstalk rebuild-environment \
  --environment-id <env-id> \
  --output json
```

**Notes:**
- Environment must be within termination retention period
- Use environment ID (e-xxxxxxxx), not name
- Restores with same configuration
- May take several minutes

### Check Restore Progress
```bash
aws elasticbeanstalk describe-environments \
  --environment-ids <env-id> \
  --output json
```

## Clone Environment

Create identical environment from existing.

### Quick Clone (Recommended)
```bash
# Step 1: Get source environment ID and create unique template name
SOURCE_ENV_ID=$(aws elasticbeanstalk describe-environments \
  --environment-names <source-env> \
  --query 'Environments[0].EnvironmentId' \
  --output text)
TEMPLATE_NAME="clone-template-$(date +%s)"

# Step 2: Create template from source
aws elasticbeanstalk create-configuration-template \
  --application-name <app-name> \
  --template-name $TEMPLATE_NAME \
  --environment-id $SOURCE_ENV_ID \
  --output json

# Step 3: Create new environment from template
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <new-env-name> \
  --template-name $TEMPLATE_NAME \
  --output json
```

### Clone with Different CNAME
```bash
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <new-env-name> \
  --cname-prefix <new-cname> \
  --template-name <template-name> \
  --output json
```

### Clone with Different Version
```bash
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <new-env-name> \
  --version-label "v2.0.0" \
  --template-name <template-name> \
  --output json
```

### Manual Clone (Full Control)
```bash
# Get current config
aws elasticbeanstalk describe-configuration-settings \
  --application-name <app-name> \
  --environment-name <source-env> \
  --output json > source-config.json

# Create template from source
aws elasticbeanstalk create-configuration-template \
  --application-name <app-name> \
  --template-name clone-template \
  --environment-id <source-env-id> \
  --output json

# Create new environment from template
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <new-env-name> \
  --template-name clone-template \
  --output json
```

## Environment Tags

Add tags during creation:
```bash
aws elasticbeanstalk create-environment \
  --application-name <app-name> \
  --environment-name <env-name> \
  --solution-stack-name "..." \
  --tags Key=Environment,Value=production Key=Team,Value=backend \
  --output json
```

Update tags on existing:
```bash
aws elasticbeanstalk update-tags-for-resource \
  --resource-arn arn:aws:elasticbeanstalk:<region>:<account>:environment/<app>/<env> \
  --tags-to-add Key=CostCenter,Value=12345 \
  --output json
```

## Presenting Environment Info

Example output:
```
=== Created Environment ===

Name: my-app-prod
ID: e-xxxxxxxxxx
Status: Launching
Health: Grey (Pending)
CNAME: my-app-prod.us-east-1.elasticbeanstalk.com
Platform: 64bit Amazon Linux 2023 v6.7.2 running Node.js 20

Estimated time: 5-10 minutes

Monitor progress:
aws elasticbeanstalk describe-events --environment-name my-app-prod
```

## Error Handling

### CNAME Already Taken
```
CNAME prefix is already in use. Try a different prefix:
aws elasticbeanstalk check-dns-availability --cname-prefix <alternative>
```

### Invalid Solution Stack
```
Solution stack not found. List available stacks:
aws elasticbeanstalk list-available-solution-stacks | grep -i <platform>
```

### Environment Limit Reached
```
Maximum number of environments reached. Terminate unused environments or request limit increase.
```

### Creation Failed
```
Environment creation failed. Check events:
aws elasticbeanstalk describe-events --environment-name <env-name> --severity ERROR
```

## Composability

- **Deploy to new environment**: Use `deploy` skill
- **Configure environment**: Use `config` skill
- **Check health**: Use `health` skill
- **View logs**: Use `logs` skill

## Additional Resources

For detailed reference information, see the shared reference files:

- [Configuration Options](../_shared/references/config-options.md) - All available configuration namespaces and options
- [Health States](../_shared/references/health-states.md) - Health colors, statuses, and thresholds
- [Cost Optimization](../_shared/references/cost-optimization.md) - Instance sizing, scaling, and cost-saving strategies
- [Platforms](../_shared/references/platforms.md) - Platform-specific configuration and requirements
