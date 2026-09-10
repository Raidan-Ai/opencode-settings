---
name: alibaba-cloud
description: Alibaba Cloud (Aliyun) development and infrastructure. Covers ECS, OSS, RDS, SLB, VPC, RAM, aliyun CLI, DashScope/Qwen models, and the Alibaba Cloud MCP servers. Activate for any Alibaba Cloud provisioning, deployment, networking, storage, or IaC task.
---

# Alibaba Cloud Skill

## Purpose

Provides Alibaba Cloud (Aliyun) development capabilities across compute (ECS), object storage (OSS), relational databases (RDS), load balancing (SLB), virtual networks (VPC), identity (RAM), serverless/Container Service (ACK/FC), and AI models (DashScope/Qwen). Enables provisioning, deployment, networking, and cost management using the `aliyun` CLI and official MCP servers.

## When to Activate

- Provisioning ECS instances, RDS databases, or OSS buckets
- Configuring VPC networking, security groups, SLB, or DNS
- Managing RAM users, roles, and policies (least privilege)
- Deploying apps to ACK (Kubernetes) or Function Compute (serverless)
- Invoking DashScope / Qwen foundation models
- Writing Terraform or IaC for Alibaba Cloud
- Using the Alibaba Cloud MCP server for agent-assisted ops

## Core Knowledge

### Alibaba Cloud MCP Options (verified official)

| Option | Command | Env Vars | Source |
|--------|---------|----------|--------|
| **Ops MCP Server** (AWS-style, stdio) | `uvx alibaba-cloud-ops-mcp-server@latest` | `ALIBABA_CLOUD_ACCESS_KEY_ID`, `ALIBABA_CLOUD_ACCESS_KEY_SECRET` | github.com/aliyun/alibaba-cloud-ops-mcp-server |
| **Agent Toolkit** (skills + MCP proxy) | `npx openplugin aliyun/alibabacloud-agent-toolkit` · proxy: `uvx alibabacloud.mcp-proxy@latest` | `ALIBABACLOUD_TELEMETRY=false`, `ALIBABACLOUD_TRACE=false` | github.com/aliyun/alibabacloud-agent-toolkit |

- **Two families**: (1) Ops server = direct AK/SK auth via `uvx`; (2) Agent Toolkit = openplugin platform that installs skills + MCP proxy (`uvx` for telemetry-view).
- **Auth** uses AccessKey ID + Secret (never commit these to source; use env vars / secret store).
- Agent Toolkit requires [uv](https://docs.astral.sh/uv/) for the `uvx`-based components.

### Aliyun CLI

```bash
# Configure credentials (AK/SK + region)
aliyun configure

# Set profile env vars (preferred for scripts/CI)
export ALIBABA_CLOUD_ACCESS_KEY_ID=xxx
export ALIBABA_CLOUD_ACCESS_KEY_SECRET=xxx
export ALIBABA_CLOUD_REGION_ID=cn-hangzhou

# Common service groups
aliyun ecs DescribeRegions
aliyun ecs RunInstances --RegionId cn-hangzhou ...
aliyun oss ls
aliyun rds DescribeDBInstances
aliyun ram ListUsers
```

### Service Quick Reference

- **ECS** (Elastic Compute Service): virtual machines, images, security groups, auto-scaling, pay-as-you-go / subscription.
- **OSS** (Object Storage Service): S3-compatible object storage; buckets, objects, lifecycle, ACLs.
- **RDS** (Relational Database Service): managed MySQL/PostgreSQL/SQL Server/Redis.
- **SLB** (Server Load Balancer) + ALB: distribute traffic across ECS/container backends.
- **VPC** (Virtual Private Cloud): networks, vSwitches, security groups, NAT gateways, EIPs.
- **RAM** (Resource Access Management): users, roles, policies, STS temporary credentials.
- **ACK** (Container Service for Kubernetes): managed K8s.
- **FC** (Function Compute): serverless functions.
- **DashScope / Bailian**: model studio hosting **Qwen** LLM family (OpenAI-compatible `/v1` endpoint).

### Terraform / IaC

```hcl
provider "alicloud" {
  region = "cn-hangzhou"
  # credentials from ALICLOUD_ACCESS_KEY / ALICLOUD_SECRET_KEY env
}

resource "alicloud_vpc" "main" {
  vpc_name = "main"
  cidr_block = "10.0.0.0/16"
}

resource "alicloud_vswitch" "main" {
  vpc_id     = alicloud_vpc.main.id
  cidr_block = "10.0.1.0/24"
  zone_id    = "cn-hangzhou-b"
}

resource "alicloud_instance" "web" {
  instance_name        = "web"
  availability_zone    = "cn-hangzhou-b"
  image_id             = "ubuntu_24_04_x64_20G_alibase_20240528.vhd"
  instance_type        = "ecs.g6.large"
  vswitch_id           = alicloud_vswitch.main.id
  security_groups      = [alicloud_security_group.web.id]
  instance_charge_type = "PostPaid"
  internet_charge_type = "PayByTraffic"
}

resource "alicloud_security_group" "web" {
  name        = "web"
  vpc_id      = alicloud_vpc.main.id
}
```

## Workflow

1. **Choose auth**: prefer `ALIBABA_CLOUD_ACCESS_KEY_ID`/`ALIBABA_CLOUD_ACCESS_KEY_SECRET` env vars; use RAM roles + STS for long-running services over root keys.
2. **Set region** explicitly (`ALIBABA_CLOUD_REGION_ID`); never assume a default region.
3. **Provision** via aliyun CLI, Terraform, or the Ops MCP server.
4. **Harden**: VPC + security groups (deny-all by default), RAM least privilege, private subnets for DB.
5. **Enable observability**: CloudMonitor alerts + SLB health checks; log to SLS (Log Service).
6. **Verify**: air of action attained → describe the created resources and test connectivity.
7. **Clean up**: terminate pay-as-you-go resources to avoid cost leakage.

## Tools

```bash
aliyun --version        # CLI
aliyun configure        # interactive credential setup
aliyun ecs --help       # service-specific help
terraform plan/apply    # IaC (provider alicloud)
uvx alibaba-cloud-ops-mcp-server@latest   # MCP (stdin/stdout)
```

### MCP Requirements

```jsonc
"alibaba-cloud-ops": {
  "type": "local",
  "command": ["uvx", "alibaba-cloud-ops-mcp-server@latest"],
  "environment": {
    "ALIBABA_CLOUD_ACCESS_KEY_ID": "",
    "ALIBABA_CLOUD_ACCESS_KEY_SECRET": ""
  },
  "enabled": false
}
```

- Start with `"enabled": false`; flight-check in a live session before enabling.
- Prefer RAM + STS over long-lived root AK/SK.

## Best Practices

1. Use env vars or secret managers, never hardcode AK/SK in code or config.
2. Scope RAM policies to least privilege; rotate access keys.
3. Always set `RegionId` explicitly.
4. Prefer managed services (RDS, ACK, OSS) over self-managed equivalents.
5. Isolate tiers into separate security groups; DB in private vSwitch, only app tier exposed.
6. Tag resources (env, owner, cost-center) for governance and billing.
7. Use CloudMonitor + alarms for production workloads.
8. Pin Terraform provider and module versions.

## Anti-patterns

- ❌ Committing AccessKey IDs/Secrets to git (`ALIBABA_CLOUD_ACCESS_KEY_SECRET` in source).
- ❌ Using the root account keys for app workloads (use RAM user/role).
- ❌ Opening 0.0.0.0/0 in security groups for SSH/DB.
- ❌ Assuming a default region; operations silently run in the wrong region.
- ❌ Leaving expensive pay-as-you-go instances running (cost leakage).
- ❌ Mixing environments (prod/staging) in one VPC without isolation.

## Verification

```bash
# Credentials + region configured
aliyun ecs DescribeRegions --output cols=RegionId rows=Regions.Region

# List instances in the target region
aliyun ecs DescribeInstances --RegionId cn-hangzhou

# OSS bucket list / object count
aliyun oss ls

# MCP server availability (needs uvx)
uvx alibaba-cloud-ops-mcp-server@latest --help
```

- After any provisioning, run the corresponding `aliyun <svc> Describe*` to confirm the resource exists with expected config.
- Check security group rules allow only intended ports (22/80/443) from intended CIDRs.

## Examples

### DashScope / Qwen invocation (OpenAI-compatible)

```bash
export DASHSCOPE_API_KEY=xxx
curl https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions \
  -H "Authorization: Bearer $DASHSCOPE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen-max",
    "messages": [{"role": "user", "content": "Explain serverless in one sentence."}]
  }'
```

### Creating an OSS bucket

```bash
aliyun oss mb oss://my-app-assets --region cn-hangzhou
aliyun oss cp ./dist oss://my-app-assets/dist/ --recursive
```

### Qwen via Agents (skills platform)

```bash
# Install the Agent Toolkit (handles QoderWork hook registration)
npx openplugin aliyun/alibabacloud-agent-toolkit

# Disable telemetry/tracing for privacy
export ALIBABACLOUD_TELEMETRY=false
export ALIBABACLOUD_TRACE=false
```
