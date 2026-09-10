---
name: google-cloud
description: Google Cloud Platform development, gcloud CLI operations, GCE/GKE/Cloud Run/BigQuery/IAM, Application Default Credentials, and Google Cloud gcloud MCP server integration. Activate for GCP resource management, gcloud CLI tasks, GKE deployment, Cloud Run services, BigQuery queries, or Google Cloud MCP tool usage.
---

# Google Cloud Skill

## Purpose
Provides comprehensive Google Cloud Platform development: gcloud CLI operations, GCE/GKE/Cloud Run/BigQuery/IAM management, Application Default Credentials (ADC) setup, and gcloud MCP server integration for AI-assisted GCP operations.

## When to Activate
- Managing GCP resources via the `gcloud` CLI
- Deploying to GKE, Cloud Run, or Compute Engine
- Writing BigQuery SQL or managing datasets
- Configuring IAM/service accounts on GCP
- Setting up Google Cloud MCP servers for AI-assisted operations
- Debugging GCP resource issues or access errors

## Core Knowledge

### gcloud CLI Authentication
```bash
gcloud auth login                                # interactive (browser)
gcloud auth application-default login            # ADC for SDKs/programs
gcloud auth activate-service-account mysa@my-project.iam.gserviceaccount.com \
  --key-file=key.json
gcloud config set project my-project-id
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

### Compute Engine
```bash
gcloud compute instances create my-vm \
  --zone=us-central1-a --machine-type=e2-medium \
  --image-family=debian-12 --image-project=debian-cloud \
  --tags=http-server
gcloud compute ssh my-vm --zone=us-central1-a
gcloud compute instances list --format="table(name,zone,status,machineType.basename())"
gcloud compute instances delete my-vm --zone=us-central1-a
```

### GKE
```bash
gcloud container clusters create my-cluster --zone=us-central1-a \
  --num-nodes=2 --machine-type=e2-medium \
  --enable-autoscaling --min-nodes=1 --max-nodes=5
gcloud container clusters get-credentials my-cluster --zone=us-central1-a
gcloud container clusters resize my-cluster --zone=us-central1-a \
  --node-pool default-pool --num-nodes=3
```

### Cloud Run
```bash
gcloud run deploy my-service \
  --image gcr.io/my-project/my-image:latest \
  --region us-central1 --platform managed \
  --allow-unauthenticated --port 8080
gcloud run services list --region us-central1
gcloud run services describe my-service --region us-central1   # URL, traffic split
```

### BigQuery
```bash
bq query --use_legacy_sql=false '
SELECT date, SUM(revenue) AS total_revenue
FROM `my-project.analytics.sales`
WHERE date >= "2024-01-01"
GROUP BY date ORDER BY date DESC'
bq mk --dataset --location=US my-project:analytics
bq load --autodetect --skip_leading_rows=1 my-project:analytics.sales sales.csv
```

### IAM (Service Accounts)
```bash
gcloud iam service-accounts create my-app-sa --display-name="My App SA"
gcloud projects add-iam-policy-binding my-project \
  --member="serviceAccount:my-app-sa@my-project.iam.gserviceaccount.com" \
  --role="roles/run.invoker"
gcloud iam service-accounts keys create key.json \
  --iam-account=my-app-sa@my-project.iam.gserviceaccount.com
gcloud iam service-accounts keys list \
  --iam-account=my-app-sa@my-project.iam.gserviceaccount.com   # detect key sprawl
```

### ADC Best Practices
```bash
# Local dev:  gcloud auth application-default login
# VMs:        attach service account at instance creation (no key file)
gcloud compute instances create my-vm \
  --service-account=my-sa@my-project.iam.gserviceaccount.com --scopes=cloud-platform
# CI/CD:      use Workload Identity Federation (never commit SA keys)
```

## Workflow
```bash
# 1. Login + set project
gcloud auth login
gcloud config set project my-project

# 2. Deploy
gcloud run deploy my-api --image gcr.io/my-project/my-api:latest --region us-central1
# or: kubectl apply -f k8s/manifest.yaml   (GKE)

# 3. Debug & monitor
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=my-api" --limit=20
kubectl logs -f deployment/my-app
gcloud logging read "protoPayload.principalEmail=mysa@my-project.iam.gserviceaccount.com" --limit=10
```

## Tools
```bash
gcloud --version                    # CLI version
gcloud config list                  # active project/region/zone
gcloud auth list                    # credentialed accounts
bq version                          # BigQuery CLI
```

## MCP Requirements

### Google Cloud gcloud MCP (googleapis/gcloud-mcp)
- **Repo**: github.com/googleapis/gcloud-mcp (preview, not an officially supported Google product)
- **Servers**: `gcloud`, `observability`, `storage`, `backupdr` — all `@google-cloud/*-mcp` npm packages
- **Prereqs**: Node.js ≥ 20 + gcloud CLI installed; permissions = active `gcloud` account
- **Auth**: gcloud CLI / ADC — NO API keys; service-account impersonation supported for least privilege

### opencode.jsonc Config Blocks
```jsonc
"google-gcloud": {
  "type": "local",
  "command": ["npx", "-y", "@google-cloud/gcloud-mcp"],
  "enabled": false
},
"google-observability": {
  "type": "local",
  "command": ["npx", "-y", "@google-cloud/observability-mcp"],
  "enabled": false
},
"google-storage": {
  "type": "local",
  "command": ["npx", "-y", "@google-cloud/storage-mcp"],
  "enabled": false
}
```

## Best Practices
1. **ADC over service account keys**: Workload Identity or instance-attached SAs for production
2. **Organization policies**: Enforce constraints (e.g. `constraints/compute.vmExternalIpAccess`)
3. **Cost management**: Budgets + alerts; committed-use discounts for GKE
4. **Resource labeling**: `env`, `team`, `cost-center` labels on everything for billing
5. **Least privilege**: Predefined roles over `roles/editor`; audit keys with `keys list`
6. **Regional resources**: Choose regions deliberately; regional > zonal for HA

## Anti-patterns
- ❌ Committing service account keys to repos (use Workload Identity Federation)
- ❌ Creating resources without labels (untraceable costs)
- ❌ Hardcoding project IDs (use `gcloud config get-value project`)
- ❌ Skipping Organization Policy constraints
- ❌ GKE clusters without autoscaling or maintenance windows

## Verification
```bash
gcloud --version                                     # CLI installed
gcloud auth application-default print-access-token   # ADC works (truncate output)
gcloud container clusters describe my-cluster --zone=us-central1-a \
  --format="table(name,currentNodeCount,status)"
npx -y @google-cloud/gcloud-mcp --help               # MCP package installs
```

## Examples
```bash
# Full workflow: deploy Cloud Run with dedicated SA
SA="my-api-sa"; PROJ=$(gcloud config get-value project)
gcloud iam service-accounts create $SA --display-name="My API"
gcloud projects add-iam-policy-binding $PROJ \
  --member="serviceAccount:${SA}@${PROJ}.iam.gserviceaccount.com" --role="roles/run.invoker"
gcloud run deploy my-api \
  --image gcr.io/${PROJ}/my-api:latest --region us-central1 \
  --service-account ${SA}@${PROJ}.iam.gserviceaccount.com --no-allow-unauthenticated
```