---
name: app
description: This skill should be used when the user wants to manage Elastic Beanstalk applications (not environments), says "eb init", "eb appversion", "application versions", "version lifecycle", "list applications", "delete version", "initialize project", "create beanstalk app", "new eb application", "list applications", "my beanstalk apps", or needs to manage application-level resources. For environment operations use environment skill.
---

# Application Management

Initialize projects, manage application versions, and configure version lifecycle using the EB CLI.

## When to Use

- Initialize an EB project (`eb init`)
- List applications
- Manage application versions
- Configure version lifecycle rules

## When NOT to Use

- Managing environments → use `environment` skill
- Deploying code → use `deploy` skill
- Checking status → use `status` skill

---

## Initialize

```bash
eb init
eb init <app-name> --region <region> --platform "<platform>"
```

## List Applications

```bash
eb init --list
```

## Application Versions

```bash
eb appversion                            # List versions
eb appversion --delete <version-label>   # Delete version
```

## Version Lifecycle

```bash
eb appversion lifecycle                  # Configure lifecycle rules
```

Or via AWS CLI:
```bash
aws elasticbeanstalk update-application-resource-lifecycle \
  --application-name <app-name> \
  --resource-lifecycle-config '{
    "VersionLifecycleConfig": {
      "MaxCountRule": {"Enabled": true, "MaxCount": 200, "DeleteSourceFromS3": true},
      "MaxAgeRule": {"Enabled": true, "MaxAgeInDays": 180, "DeleteSourceFromS3": true}
    },
    "ServiceRole": "arn:aws:iam::<account>:role/aws-elasticbeanstalk-service-role"
  }' --output json
```

---

## Composability

- **Create environment**: Use `environment` skill
- **Deploy code**: Use `deploy` skill
- **Platform updates**: Use `maintenance` skill

## Additional Resources

- [Platforms](../_shared/references/platforms.md)
