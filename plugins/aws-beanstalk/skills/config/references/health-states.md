# AWS Elastic Beanstalk Health States Reference

## Health Colors

| Color | Status | Description | Action Required |
|-------|--------|-------------|-----------------|
| **Green** | Healthy | All systems operational | None |
| **Yellow** | Warning | Minor issues detected | Monitor closely |
| **Red** | Degraded | Significant problems | Investigate immediately |
| **Grey** | Unknown | Cannot determine health | Check configuration |

## Health Status Values

### Environment Health Status

| Status | Color | Description |
|--------|-------|-------------|
| `Ok` | Green | All health checks passing, metrics within thresholds |
| `Warning` | Yellow | Some instances unhealthy or metrics slightly elevated |
| `Degraded` | Red | Multiple instances failing or high error rates |
| `Severe` | Red | Critical failure, service likely unavailable |
| `Info` | Yellow | Environment is updating or transitioning |
| `Pending` | Grey | Health status being evaluated |
| `Unknown` | Grey | Cannot determine health |
| `Suspended` | Grey | Health monitoring suspended |
| `NoData` | Grey | No health data available |

### Instance Health Status

| Status | Description |
|--------|-------------|
| `Ok` | Instance passing all health checks |
| `Warning` | Instance has minor issues |
| `Degraded` | Instance failing health checks |
| `Severe` | Instance critically unhealthy |
| `Info` | Instance is being updated |
| `Pending` | Instance launching or initializing |
| `Unknown` | Cannot determine status |
| `NoData` | No data from instance |

## Health Metrics Thresholds

### Request Metrics
| Metric | Warning | Severe |
|--------|---------|--------|
| 4xx Error Rate | > 10% | > 25% |
| 5xx Error Rate | > 1% | > 5% |
| P99 Latency | > 2000ms | > 5000ms |

### System Metrics
| Metric | Warning | Severe |
|--------|---------|--------|
| CPU Utilization | > 80% | > 95% |
| Instance Health Check | 2 failures | 5+ failures |

## Health Check Flow

```
Request → Load Balancer → Health Check Path → Application
                              ↓
                     200-399 = Healthy
                     400-499 = Client Error (counted)
                     500-599 = Unhealthy
                     Timeout = Unhealthy
```

## Common Health Issues

### Yellow Health - Causes

1. **Deployment in progress**
   - Normal during rolling deployments
   - Wait for deployment to complete

2. **Some instances unhealthy**
   - Check instance-level health
   - Review instance logs

3. **Elevated latency**
   - P99 above threshold
   - Check for resource bottlenecks

4. **Moderate error rate**
   - 4xx/5xx errors above baseline
   - Check application logs

### Red Health - Causes

1. **Multiple failing instances**
   - Health checks failing
   - Application crashing

2. **High error rate**
   - > 5% 5xx responses
   - Database or dependency issues

3. **Deployment failure**
   - Build failed
   - Start command error

4. **Resource exhaustion**
   - Out of memory
   - Disk full

### Grey Health - Causes

1. **Enhanced health not enabled**
   - Basic health only shows instance status
   - Enable enhanced health for detailed metrics

2. **Environment launching**
   - Wait for instances to initialize

3. **No running instances**
   - Environment terminated
   - Auto scaling set to 0

## Health Data Sources

### Basic Health
- EC2 instance status checks
- ELB health checks only
- Limited visibility

### Enhanced Health
- Application-level metrics
- Request latency percentiles
- Error rate tracking
- CPU, memory per instance
- Deployment tracking

## Interpreting Health Causes

Common `Causes` field values:

```json
{
  "Causes": [
    "1 instance is not healthy.",
    "P99 latency is above warning threshold of 2000 ms.",
    "5xx error rate is above warning threshold of 1%.",
    "CPU utilization is above 80%.",
    "Instance ELB health has been 'OutOfService' for 2 minutes."
  ]
}
```

## Health Check Configuration

### Recommended Settings

```
Health Check Path: /health (or /healthz, /api/health)
Interval: 15-30 seconds
Timeout: 5-10 seconds
Healthy Threshold: 2-3 checks
Unhealthy Threshold: 5 checks
```

### Health Check Endpoint Best Practices

```javascript
// Example /health endpoint
app.get('/health', (req, res) => {
  // Basic health check
  res.status(200).json({ status: 'ok' });
});

// Comprehensive health check
app.get('/health', async (req, res) => {
  try {
    await db.query('SELECT 1');
    res.status(200).json({
      status: 'ok',
      database: 'connected',
      uptime: process.uptime()
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      database: 'disconnected'
    });
  }
});
```

## Monitoring Commands

### Environment Health
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name <env> \
  --attribute-names Status HealthStatus Color Causes
```

### Instance Health
```bash
aws elasticbeanstalk describe-instances-health \
  --environment-name <env> \
  --attribute-names HealthStatus Color Causes System
```

### Application Metrics
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name <env> \
  --attribute-names ApplicationMetrics
```
