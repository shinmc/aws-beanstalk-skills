# AWS Elastic Beanstalk Configuration Options Reference

## Configuration Namespaces

### Auto Scaling

#### aws:autoscaling:asg
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| MinSize | Integer | 1 | Minimum instances in ASG |
| MaxSize | Integer | 4 | Maximum instances in ASG |
| Cooldown | Integer | 360 | Seconds between scaling activities |
| Availability Zones | String | Any | AZs to launch instances in |

#### aws:autoscaling:launchconfiguration
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| InstanceType | String | t2.micro | EC2 instance type |
| EC2KeyName | String | - | SSH key pair name |
| IamInstanceProfile | String | aws-elasticbeanstalk-ec2-role | IAM instance profile |
| RootVolumeType | String | gp2 | EBS volume type |
| RootVolumeSize | Integer | 8 | Volume size in GB |
| RootVolumeIOPS | Integer | - | Provisioned IOPS |

#### aws:autoscaling:trigger
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| MeasureName | String | NetworkOut | Metric for scaling (CPUUtilization, NetworkOut, etc.) |
| Statistic | String | Average | Statistic type |
| Unit | String | Bytes | Metric unit |
| Period | Integer | 5 | Evaluation period (minutes) |
| BreachDuration | Integer | 5 | Duration before scaling |
| LowerThreshold | Integer | 2000000 | Scale in threshold |
| UpperThreshold | Integer | 6000000 | Scale out threshold |
| LowerBreachScaleIncrement | Integer | -1 | Instances to remove |
| UpperBreachScaleIncrement | Integer | 1 | Instances to add |

### Load Balancer

#### aws:elb:loadbalancer
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| CrossZone | Boolean | true | Enable cross-zone load balancing |
| SecurityGroups | String | - | Security group IDs |
| ManagedSecurityGroup | String | - | Managed security group |

#### aws:elb:listener
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| ListenerProtocol | String | HTTP | LB protocol (HTTP, HTTPS, TCP, SSL) |
| InstanceProtocol | String | HTTP | Instance protocol |
| InstancePort | Integer | 80 | Instance port |
| ListenerEnabled | Boolean | true | Enable listener |

#### aws:elbv2:listener:default (ALB)
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| ListenerEnabled | Boolean | true | Enable listener |
| Protocol | String | HTTP | Protocol (HTTP, HTTPS) |
| Rules | String | - | Listener rules |

### Environment

#### aws:elasticbeanstalk:environment
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| EnvironmentType | String | LoadBalanced | SingleInstance or LoadBalanced |
| ServiceRole | String | - | EB service role ARN |
| LoadBalancerType | String | classic | classic, application, or network |
| LoadBalancerIsShared | Boolean | false | Use shared ALB |

#### aws:elasticbeanstalk:environment:process:default
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| DeregistrationDelay | Integer | 20 | Deregistration delay (seconds) |
| HealthCheckInterval | Integer | 15 | Health check interval |
| HealthCheckPath | String | / | Health check URL path |
| HealthCheckTimeout | Integer | 5 | Health check timeout |
| HealthyThresholdCount | Integer | 3 | Healthy threshold |
| UnhealthyThresholdCount | Integer | 5 | Unhealthy threshold |
| MatcherHTTPCode | String | 200 | Expected HTTP codes |
| Port | Integer | 80 | Instance port |
| Protocol | String | HTTP | Protocol |
| StickinessEnabled | Boolean | false | Enable sticky sessions |
| StickinessLBCookieDuration | Integer | 86400 | Cookie duration |

### Application Environment

#### aws:elasticbeanstalk:application:environment
Dynamic option names - each environment variable is an option:
```
Namespace: aws:elasticbeanstalk:application:environment
OptionName: MY_VAR
Value: my-value
```

### Health Reporting

#### aws:elasticbeanstalk:healthreporting:system
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| SystemType | String | basic | basic or enhanced |
| ConfigDocument | JSON | - | CloudWatch custom metrics config |
| EnhancedHealthAuthEnabled | Boolean | true | Require auth for health agent |

### Managed Updates

#### aws:elasticbeanstalk:managedactions
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| ManagedActionsEnabled | Boolean | false | Enable managed updates |
| PreferredStartTime | String | - | Maintenance window (e.g., "Sun:10:00") |
| ServiceRoleForManagedUpdates | String | - | Service role ARN |

#### aws:elasticbeanstalk:managedactions:platformupdate
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| UpdateLevel | String | - | patch, minor, or major |
| InstanceRefreshEnabled | Boolean | false | Replace instances during update |

### Platform-Specific

#### aws:elasticbeanstalk:container:nodejs
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| NodeCommand | String | - | Command to start app |
| NodeVersion | String | - | Node.js version |
| ProxyServer | String | nginx | Proxy server (nginx, apache, none) |
| GzipCompression | Boolean | true | Enable gzip |

#### aws:elasticbeanstalk:container:python
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| WSGIPath | String | application.py | WSGI module path |
| NumProcesses | Integer | 1 | Gunicorn workers |
| NumThreads | Integer | 15 | Threads per worker |

### VPC

#### aws:ec2:vpc
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| VPCId | String | - | VPC ID |
| Subnets | String | - | Comma-separated subnet IDs |
| ELBSubnets | String | - | Load balancer subnets |
| ELBScheme | String | public | public or internal |
| AssociatePublicIpAddress | Boolean | - | Assign public IP |

### Updates and Deployments

#### aws:elasticbeanstalk:command
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| DeploymentPolicy | String | AllAtOnce | AllAtOnce, Rolling, RollingWithAdditionalBatch, Immutable, TrafficSplitting |
| BatchSizeType | String | Percentage | Percentage or Fixed |
| BatchSize | Integer | 100 | Batch size for rolling |
| Timeout | Integer | 600 | Command timeout (seconds) |
| IgnoreHealthCheck | Boolean | false | Ignore health during deploy |

#### aws:autoscaling:updatepolicy:rollingupdate
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| RollingUpdateEnabled | Boolean | false | Enable rolling updates |
| RollingUpdateType | String | Time | Time or Health |
| MaxBatchSize | Integer | 1 | Max instances per batch |
| MinInstancesInService | Integer | 0 | Min healthy instances |
| PauseTime | String | - | Pause between batches |
| Timeout | String | PT30M | Update timeout |

### Notifications

#### aws:elasticbeanstalk:sns:topics
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Notification Endpoint | String | - | Email or SNS ARN |
| Notification Protocol | String | email | email, http, https, sqs |
| Notification Topic ARN | String | - | SNS topic ARN |
| Notification Topic Name | String | - | SNS topic name |

## Common Configuration Patterns

### Production Environment
```json
[
  {"Namespace": "aws:autoscaling:asg", "OptionName": "MinSize", "Value": "2"},
  {"Namespace": "aws:autoscaling:asg", "OptionName": "MaxSize", "Value": "10"},
  {"Namespace": "aws:autoscaling:launchconfiguration", "OptionName": "InstanceType", "Value": "t3.medium"},
  {"Namespace": "aws:elasticbeanstalk:healthreporting:system", "OptionName": "SystemType", "Value": "enhanced"},
  {"Namespace": "aws:elasticbeanstalk:command", "OptionName": "DeploymentPolicy", "Value": "Rolling"},
  {"Namespace": "aws:elasticbeanstalk:command", "OptionName": "BatchSize", "Value": "30"}
]
```

### Development Environment
```json
[
  {"Namespace": "aws:elasticbeanstalk:environment", "OptionName": "EnvironmentType", "Value": "SingleInstance"},
  {"Namespace": "aws:autoscaling:launchconfiguration", "OptionName": "InstanceType", "Value": "t3.micro"}
]
```
