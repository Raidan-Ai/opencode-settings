---
name: devops-sre
description: Provides DevOps and Site Reliability Engineering expertise including CI/CD (GitHub Actions), deployment strategies, infrastructure as code, monitoring and observability (Prometheus, Grafana, Loki, Jaeger/OpenTelemetry), incident response, backup/disaster recovery, performance, and capacity planning. Activate for any CI/CD pipeline, deployment, infrastructure, monitoring, alerting, or site reliability task.
---

# DevOps & SRE Skill

## Purpose
Provides DevOps and Site Reliability Engineering expertise including CI/CD pipelines, deployment strategies, release management, infrastructure as code, monitoring, observability (Prometheus, Grafana, Loki, Jaeger/OpenTelemetry), incident response, backup/disaster recovery, performance engineering, and capacity planning. Enables building reliable, observable, and automated infrastructure.

## When to Activate
- Setting up or modifying CI/CD pipelines (GitHub Actions, GitLab CI)
- Designing deployment strategies (blue-green, canary, rolling)
- Implementing monitoring, alerting, or observability stacks
- Incident response planning or post-mortem analysis
- Infrastructure provisioning with Terraform, Pulumi, or CloudFormation
- Performance profiling, load testing, or capacity planning
- Disaster recovery planning and backup automation
- Log aggregation, distributed tracing, or metrics collection

## Core Knowledge

### CI/CD Pipeline Architecture
```
Code Commit → Lint → Unit Test → Build → Integration Test → Security Scan → Deploy → Verify
    ↓           ↓       ↓          ↓          ↓                ↓            ↓         ↓
  Trigger    ESLint   pytest   Docker/     Test suite      SAST/DAST    Staging    Health
  (push/PR)          vitest   webpack     (parallel)      (semgrep/     (auto)     checks
                                                       trivy)
```

### GitHub Actions Workflow (Build + Test + Deploy)
```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Unit tests
        run: npm test -- --coverage

      - name: Build
        run: npm run build

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: dist/

  security-scan:
    needs: build-and-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Semgrep SAST
        uses: semgrep/semgrep-action@v1
        with:
          config: p/default
      - name: Trivy vulnerability scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          severity: 'CRITICAL,HIGH'

  deploy:
    needs: [build-and-test, security-scan]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - name: Download build artifacts
        uses: actions/download-artifact@v4
        with:
          name: build-output
          path: dist/
      - name: Deploy to production
        run: |
          echo "Deploying version ${{ github.sha }}"
          # Deploy logic here
      - name: Verify deployment
        run: curl -sf https://api.example.com/health || exit 1
```

### Docker Healthcheck
```dockerfile
# Optimal healthcheck pattern
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# For non-HTTP services (gRPC)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD grpc_health_probe -addr=:50051 || exit 1
```

### Prometheus Scrape Configuration
```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alerts/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  - job_name: 'application'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['app:8080']
        labels:
          env: production
          service: api

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'docker'
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
    relabel_configs:
      - source_labels: [__meta_docker_container_name]
        target_label: container_name
```

### SLI / SLO Framework
```
SLI (Service Level Indicator) → What you measure
  - Availability: successful requests / total requests
  - Latency: percentage of requests under threshold
  - Error rate: 5xx responses / total responses
  - Throughput: requests processed per second

SLO (Service Level Objective) → Target value for SLI
  - Availability SLO: 99.9% (8.76 hours downtime/year)
  - Latency SLO: 99% of requests < 200ms
  - Error rate SLO: < 0.1% of requests return 5xx

SLA (Service Level Agreement) → Contractual commitment
  - Includes consequences of missing SLO
  - Usually less strict than SLO (SLO + buffer = SLA)

Error Budget = 1 - SLO
  - 99.9% SLO → 0.1% error budget → 43.2 min/month
  - Team can "spend" budget on risky deployments
  - Budget exhausted → freeze non-critical changes
```

### Structured Logging (JSON)
```json
{
  "timestamp": "2026-01-15T10:30:45.123Z",
  "level": "info",
  "message": "Request processed",
  "service": "api-gateway",
  "trace_id": "abc123def456",
  "span_id": "789ghi012",
  "duration_ms": 45,
  "method": "POST",
  "path": "/api/v1/orders",
  "status_code": 201,
  "user_id": "u_12345"
}
```

### Observability Stack
```
                    ┌──────────────┐
                    │   Grafana    │
                    │  Dashboard   │
                    └──┬───┬───┬──┘
                       │   │   │
          ┌────────────┘   │   └────────────┐
          ▼                ▼                ▼
   ┌─────────────┐  ┌───────────┐  ┌──────────────┐
   │ Prometheus  │  │   Loki    │  │    Jaeger     │
   │  (Metrics)  │  │  (Logs)   │  │   (Traces)   │
   └──────┬──────┘  └─────┬─────┘  └──────┬───────┘
          │                │               │
   ┌──────┴──────┐  ┌─────┴─────┐  ┌──────┴───────┐
   │ /metrics    │  │   JSON    │  │  OpenTelemetry│
   │ endpoint    │  │  logs     │  │  SDK/Agent    │
   └─────────────┘  └───────────┘  └──────────────┘
```

### Deployment Strategies
```
Blue-Green:
  ┌─────────┐     ┌─────────┐
  │ Blue     │◄────│ Router  │    → Instant cutover, easy rollback
  │ (live)   │     │         │
  └─────────┘     └────┬────┘
                       │
  ┌─────────┐          │
  │ Green   │◄─────────┘
  │ (new)   │
  └─────────┘

Canary:
  ┌─────────┐
  │ v2 (5%) │◄─── Router ───┐    → Gradual rollout, auto-rollback
  └─────────┘     │         │
  ┌─────────┐     │         │
  │ v1(95%) │◄────┘         │
  └─────────┘               │
                    ┌───────┴──────┐
                    │   Metrics    │
                    │   monitor    │
                    └──────────────┘

Rolling:
  [v1][v1][v1][v1]  →  [v2][v1][v1][v1]  →  [v2][v2][v1][v1]  →  [v2][v2][v2][v2]
```

### Backup & Disaster Recovery
```
RPO (Recovery Point Objective) → max acceptable data loss (e.g., 15 min of transactions)
RTO (Recovery Time Objective)  → max acceptable downtime (e.g., 1 hour to restore service)
3-2-1 rule → 3 copies of data, on 2 different media, 1 off-site (or immutable cloud storage)
```
Backup strategy:
- Databases: nightly full backups + WAL shipping (PostgreSQL `pg_basebackup` + `archive_mode=on`) or managed snapshots
- Object storage: bucket versioning + cross-region replication
- Application state: IaC + CI-built artifacts make services reproducible without per-host backups
- Test restores: quarterly restore drills — an untested backup is a rumor

```bash
# PostgreSQL logical dump (RPO = last dump)
pg_dump -Fc -f app.dump appdb

# WAL archiving (small RPO)
# wal_level=replica, archive_mode=on, archive_command='cp %p /backup/%f'

# Restore drill
pg_restore -d appdb app.dump
```
DR runbook stages: Detect → Escalate → Failover (geo DNS / promote replica) → Restore data → Verify → Failback.

### Performance & Capacity Planning
```
Baseline → Model → Budget → Monitor → Adjust
```
- Collect baselines: request rate, p95 latency, CPU/memory, disk IO, error rate (30-day window)
- Model growth: `peak_rate × (1 + growth_rate)^months` per service and per database
- Right-size: sustained CPU < 40% → downsize; sustained > 70% → scale out/up
- Set budgets per team (e.g., p99 latency < 200ms) and alert before breach
- Validate with load tests (`hey`, `k6`, `wrk`) against staging with production-shaped traffic

## Workflow

### 1. Incident Response
```
Detection → Triage → Mitigate → Resolve → Post-mortem
   ↓          ↓         ↓          ↓          ↓
 Alert     Severity   Quick fix  Root cause  Blameless
 fires     assessment (restart,  fix         review
           (SEV1-4)   rollback,  (patch,
                      feature    config)
                      flag)
```

**SEV levels:**
- SEV1: Full outage, all users affected → 15 min response, all-hands
- SEV2: Major degradation, most users affected → 30 min response
- SEV3: Partial impact, some users affected → 1 hour response
- SEV4: Minor issue, cosmetic/low-impact → next business day

### 2. Post-Mortem Template
```markdown
## Incident: [Title]
- **Date**: YYYY-MM-DD
- **Duration**: X hours Y minutes
- **Severity**: SEV[N]
- **Impact**: [What users experienced]

## Timeline (UTC)
- HH:MM: [Event]
- HH:MM: [Event]

## Root Cause
[Technical root cause]

## What Went Well
- [Positive]

## What Went Wrong
- [Negative]

## Action Items
- [ ] [Owner] Fix 1 — due YYYY-MM-DD
- [ ] [Owner] Fix 2 — due YYYY-MM-DD

## Lessons Learned
- [Takeaway]
```

### 3. Terraform Infrastructure Pattern
```hcl
# main.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "terraform-state"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}

module "vpc" {
  source  = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
  environment = var.environment
}

module "ecs" {
  source        = "./modules/ecs"
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.private_subnet_ids
  image_url     = var.image_url
  desired_count = var.desired_count
}
```

## Tools

### Package Installation
```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip && sudo mv terraform /usr/local/bin/

# Prometheus (Docker)
docker run -d -p 9090:9090 -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest

# Grafana (Docker)
docker run -d -p 3000:3000 grafana/grafana:latest

# Loki (Docker)
docker run -d -p 3100:3100 grafana/loki:latest

# Jaeger (Docker)
docker run -d -p 16686:16686 -p 14268:14268 jaegertracing/all-in-one:latest

# act (GitHub Actions local runner)
go install github.com/nektos/act@latest

# trivy (vulnerability scanner)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

### Command-Line Utilities
```bash
# Terraform
terraform init        # Initialize backend and providers
terraform plan        # Preview changes
terraform apply       # Apply changes
terraform destroy     # Tear down infrastructure
terraform fmt         # Format HCL files
terraform validate    # Validate configuration

# Docker healthcheck verification
docker inspect --format='{{.State.Health.Status}}' <container>

# Prometheus query
curl 'http://localhost:9090/api/v1/query?query=up'

# Grafana dashboard export
curl -s http://admin:admin@localhost:3000/api/dashboards/db/my-dashboard

# GitHub Actions local
act -j build-and-test    # Run specific job
act -l                   # List available jobs

# Trigger a workflow from CLI
gh workflow run ci-cd.yml --ref main
gh workflow run deploy.yml -f environment=staging
gh run watch              # Watch latest run
gh run list --limit 5

# Load testing
hey -n 10000 -c 100 -m GET https://api.example.com/health
wrk -t12 -c400 -d30s http://localhost:8080/
```

## MCP Requirements
Recommended MCP servers for DevOps/SRE work:
- **Prometheus MCP**: query metrics, alerts, and targets via the `/api/v1` endpoint
- **Grafana MCP**: dashboard and alerting API automation
- **Kubernetes MCP**: cluster inspection, rollout management, log access
- **Terraform MCP**: plan/apply inspection and infrastructure queries

```json
{
  "mcpServers": {
    "prometheus": {
      "type": "http",
      "url": "http://localhost:9090/api/v1",
      "description": "Prometheus metrics API for querying and alerting"
    },
    "grafana": {
      "type": "http",
      "url": "http://localhost:3000/api",
      "description": "Grafana dashboard and alerting API",
      "requires_api_key": true
    }
  }
}
```

## Best Practices

1. **Pipeline design**: Fail fast — run linting and unit tests first (cheapest feedback), integration tests next, security scans last
2. **Deployment safety**: Always have a rollback strategy; canary deployments reduce blast radius; feature flags decouple deploy from release
3. **Observability three pillars**: Metrics (what), Logs (why), Traces (where) — instrument all three from day one
4. **Alert hygiene**: Alert on symptoms (high error rate), not causes (CPU high); every alert should be actionable; avoid alert fatigue
5. **Infrastructure as code**: All infrastructure changes go through code review; use remote state with locking; plan before apply
6. **Secrets management**: Never commit secrets; use Vault, AWS Secrets Manager, or environment variables; rotate regularly
7. **Post-mortems are blameless**: Focus on systems and processes, not individuals; action items must have owners and deadlines
8. **SLIs drive reliability**: Choose SLIs that reflect user experience; error budgets prevent over-engineering
9. **Container health**: Always include HEALTHCHECK; use proper start periods for Java/JVM apps; set resource limits
10. **Log structure**: JSON structured logs enable machine parsing; include trace_id for distributed tracing correlation

## Anti-patterns

- ❌ Alerting on causes (CPU, memory) instead of symptoms (error rate, latency)
- ❌ Deploying without a rollback plan
- ❌ Skipping healthchecks in containers (invisible failures)
- ❌ Running infrastructure changes manually outside of IaC
- ❌ Storing secrets in environment variables of GitHub Actions (use secrets/oidc)
- ❌ No error budget — either you have an SLO or you're guessing
- ❌ Post-mortems that blame people instead of examining systems
- ❌ Deploying to production without running tests in CI
- ❌ Using `latest` tag in production containers (non-deterministic)
- ❌ Monitoring everything but alerting on nothing

## Verification

### Unit Tests
```bash
# Terraform validation
terraform validate && terraform fmt -check

# GitHub Actions workflow syntax
act --list  # Verify act can parse workflows

# Prometheus config validation
docker run --rm -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest promtool check config /etc/prometheus/prometheus.yml

# Docker healthcheck verification
docker build -t test-app . && docker run -d --name test-health test-app
sleep 15  # Wait for start period
docker inspect --format='{{.State.Health.Status}}' test-health
# Should output: "healthy"
docker rm -f test-health

# Loki config validation
docker run --rm -v $(pwd)/loki.yml:/etc/loki/loki.yml \
  grafana/loki:latest loki -config.file=/etc/loki/loki.yml --verify-config
```

### Integration Tests
- CI pipeline runs end-to-end on PR merge to staging
- Canary deployment monitors error rate for 15 min before full rollout
- Alertmanager test notification reaches on-call channel
- Terraform plan shows expected changes before apply

## Examples

### Complete Monitoring Stack (Docker Compose)
```yaml
# docker-compose.monitoring.yml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=30d'

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=changeme
    volumes:
      - grafana_data:/var/lib/grafana
      - ./dashboards:/var/lib/grafana/dashboards

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - loki_data:/loki

  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/log:/var/log:ro
      - ./promtail.yml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml

  alertmanager:
    image: prom/alertmanager:latest
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml

volumes:
  prometheus_data:
  grafana_data:
  loki_data:
```

### SLO Dashboard Definition (Grafana JSON snippet)
```json
{
  "title": "API SLO Dashboard",
  "panels": [
    {
      "title": "Availability SLI",
      "type": "stat",
      "targets": [
        {
          "expr": "sum(rate(http_requests_total{status!~'5..'}[30d])) / sum(rate(http_requests_total[30d])) * 100"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "thresholds": {
            "steps": [
              { "value": 99.9, "color": "green" },
              { "value": 99.0, "color": "yellow" },
              { "value": 0, "color": "red" }
            ]
          }
        }
      }
    },
    {
      "title": "Error Budget Remaining",
      "type": "gauge",
      "targets": [
        {
          "expr": "(1 - (1 - 0.999)) * 100 - (100 - sum(rate(http_requests_total{status!~'5..'}[30d])) / sum(rate(http_requests_total[30d])) * 100)"
        }
      ]
    }
  ]
}
```

### Incident Response Runbook
```markdown
# Runbook: High Error Rate

## Alert: `http_5xx_rate > 1% for 5 minutes`

### Step 1: Identify the scope (2 min)
```bash
# Check which endpoints are affected
curl -s "http://prometheus:9090/api/v1/query?query=topk(10,sum(rate(http_requests_total{status=~'5..'}[5m]))by(path))"

# Check if it's a specific pod/instance
curl -s "http://prometheus:9090/api/v1/query?query=sum(rate(http_requests_total{status=~'5..'}[5m]))by(pod)"
```

### Step 2: Check recent deployments (3 min)
```bash
kubectl rollout history deployment/api-server
kubectl get events --sort-by=.metadata.creationTimestamp | tail -20
```

### Step 3: Mitigate
```bash
# If caused by recent deploy — rollback
kubectl rollout undo deployment/api-server

# If infrastructure issue — check nodes
kubectl get nodes
kubectl describe node <node-name>
```

### Step 4: Monitor recovery
Watch Grafana dashboard for error rate returning to baseline.
```
