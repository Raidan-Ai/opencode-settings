---
name: azure
description: Microsoft Azure cloud development, resource management, ARM/Bicep templates, App Service, Functions, AKS, storage, Entra ID authentication, and Azure MCP Server integration. Activate for Azure resource provisioning, deployment, az CLI operations, ARM template authoring, Azure Functions development, or Azure MCP tool usage.
---

# Azure Skill

## Purpose
Provides comprehensive Azure cloud development capabilities: resource group management, ARM/Bicep templates, App Service, Azure Functions, AKS, storage accounts, Entra ID authentication, and Azure MCP Server integration for AI-assisted Azure operations.

## When to Activate
- Writing or deploying ARM/Bicep templates
- Managing Azure resources via `az` CLI or Azure MCP
- Developing Azure Functions (isolated worker)
- Configuring App Service, AKS, or storage accounts
- Working with Entra ID (formerly Azure AD) authentication
- Debugging Azure deployments or resource issues

## Core Knowledge

### Azure CLI Authentication
```bash
az login                                   # interactive (default)
az login --service-principal -u <APP_ID> -p <SECRET> --tenant <TENANT_ID>
az account set --subscription "<SUBSCRIPTION_NAME>"
az account show --output table
```

### Resource Group Management
```bash
az group create --name myRG --location eastus --tags env=dev
az group list --output table
az group delete --name myRG --yes --no-wait
az group export --name myRG --output json > template.json
```

### ARM/Bicep Templates (Bicep Preferred)
```bicep
param location string = resourceGroup().location
param appName string

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: appName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: '${appName}-plan-id'   // reference a serverfarms resource
    httpsOnly: true
    siteConfig: { linuxFxVersion: 'NODE|20-lts' }
  }
}
```

```bash
az deployment group create --resource-group myRG \
  --template-file main.bicep --parameters appName=my-app-001
az deployment group validate --resource-group myRG \
  --template-file main.bicep --parameters appName=my-app-001
```

### Azure Functions (Isolated Worker)
```csharp
[Function("HttpTrigger")]
public async Task<HttpResponseData> Run(
    [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestData req)
{
    _logger.LogInformation("HTTP trigger processed a request.");
    var response = req.CreateResponse(System.Net.HttpStatusCode.OK);
    await response.WriteStringAsync("Hello from Azure Functions!");
    return response;
}
```

### App Service Quick Deploy
```bash
az webapp create --resource-group myRG --plan myPlan --name my-webapp \
  --runtime "NODE:20-lts"
az webapp config appsettings set --resource-group myRG --name my-webapp \
  --settings WEBSITES_PORT=3000
```

### Storage Account
```bash
az storage account create --name mystorageacct --resource-group myRG \
  --location eastus --sku Standard_LRS --kind StorageV2
az storage container create --name mycontainer --account-name mystorageacct
az storage blob upload --account-name mystorageacct \
  --container-name mycontainer --name file.txt --file ./file.txt
```

### AKS Basics
```bash
az aks create --resource-group myRG --name myAKS --node-count 2 \
  --node-vm-size Standard_B2s --enable-addons monitoring --generate-ssh-keys
az aks get-credentials --resource-group myRG --name myAKS
az aks nodepool scale --resource-group myRG --cluster-name myAKS \
  --name nodepool1 --node-count 4
```

## Workflow
```bash
# 1. Login + set context
az login
az account set --subscription "My Sub"

# 2. Create resource group
az group create --name myRG --location eastus

# 3. Deploy infrastructure (validate first, then deploy)
az deployment group validate --resource-group myRG --template-file main.bicep
az deployment group create --resource-group myRG \
  --template-file main.bicep --parameters appName=myapp

# 4. Debug & monitor
az webapp log tail --resource-group myRG --name my-webapp
kubectl logs -f deployment/my-app                       # AKS
az monitor activity-log list --resource-group myRG --output table
```

## Tools
```bash
az --version                              # CLI version
az account show                           # current auth context
az bicep build --file main.bicep          # compile Bicep -> ARM JSON
az webapp log tail / az group export      # diagnostics & template export
```

## MCP Requirements

### Azure MCP Server (2.0 GA)
- **Repo**: github.com/microsoft/mcp — `servers/Azure.Mcp.Server` (github.com/Azure/azure-mcp is ARCHIVED Aug 25, 2025; do not use)
- **Install**: `npx -y @azure/mcp@latest server start` (also pip `uvx --from msmcp-azure azmcp server start`, NuGet `dotnet tool install Azure.Mcp`, Docker `mcr.microsoft.com/azure-sdk/azure-mcp:latest`)
- **Auth**: Azure CLI (`az login`) by default; or env `AZURE_TENANT_ID` / `AZURE_CLIENT_ID` / `AZURE_CLIENT_SECRET` (EnvironmentCredential)
- **Telemetry off**: `AZURE_MCP_COLLECT_TELEMETRY=false` (+ `AZURE_MCP_COLLECT_TELEMETRY_MICROSOFT=false`)
- **Sovereign clouds**: `--cloud AzureUSGovernment` / `azureChinaCloud` or env `AZURE_CLOUD`

### opencode.jsonc Config Block
```jsonc
"azure-mcp": {
  "type": "local",
  "command": ["npx", "-y", "@azure/mcp@latest", "server", "start"],
  "environment": { "AZURE_MCP_COLLECT_TELEMETRY": "false" },
  "enabled": false
}
```

## Best Practices
1. **Entra ID over API keys**: Managed identities or service principals with minimal roles
2. **Bicep over raw ARM JSON**: Type-safe, modular, better tooling — always validate first
3. **Resource tagging**: Tag all resources (`env`, `owner`, `cost-center`) for governance
4. **Least privilege**: Avoid Contributor; use narrow built-in or custom roles
5. **Private endpoints** for storage/databases/App Services in production
6. **Resource locks**: `az group lock create --name CanNotDelete --resource-group myRG`

## Anti-patterns
- ❌ Hardcoding subscription IDs or secrets in scripts
- ❌ Using `Contributor` when `Reader` + targeted roles suffice
- ❌ Skipping `az deployment group validate` before production deploys
- ❌ Storing connection strings in code (use Key Vault or managed identity)
- ❌ Enabling anonymous auth on function apps (`AuthorizationLevel.Anonymous` in prod)

## Verification
```bash
az version                                   # CLI installed
npx -y @azure/mcp@latest server --version    # MCP package installs
az bicep build --file main.bicep             # template compiles
az account show --query "{sub:name,user:user.name}"   # auth working
```

## Examples
```bash
# Full workflow: deploy a function app
az group create -n funcRG -l eastus --tags env=dev owner=me
az storage account create -n myfuncsa -g funcRG -l eastus --sku Standard_LRS
az functionapp create -n myfuncapp -g funcRG \
  --storage-account myfuncsa --consumption-plan-location eastus \
  --runtime dotnet-isolated --runtime-version 8 --functions-version 4
az functionapp deployment source config-zip \
  -g funcRG -n myfuncapp --src ./publish.zip
```