# Azure CI/CD Deployment Setup

This guide explains how to set up GitHub Actions to deploy Hyperledger Fabric to Azure.

## Prerequisites

- Azure subscription
- GitHub repository with write access
- Azure CLI installed locally (for initial setup)

## Step 1: Create Azure Service Principal

Create a service principal with contributor access to your subscription:

```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac \
  --name "fabric-github-deploy" \
  --role "Contributor" \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

Save the output - you'll need:
- `appId` → Client ID
- `password` → Client Secret
- `tenant` → Tenant ID

## Step 2: Add GitHub Secrets

Go to your repository **Settings → Secrets and variables → Actions** and add:

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | Service principal appId |
| `AZURE_TENANT_ID` | Service principal tenant |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |

## Step 3: Enable OIDC

For secure authentication, enable OpenID Connect:

```bash
# Get service principal object ID
SP_OBJECT_ID=$(az ad sp show --id <client-id> --query id -o tsv)

# Create federated credential
az ad app federated-credential create \
  --id <client-id> \
  --credential-name "github-deploy" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main" \
  --audience "api://AzureADTokenExchange"
```

## Workflow Usage

### Automatic Deployment

Push to `main` branch with changes in `azure-deploy/` triggers deployment:

```bash
# Make changes and push
git add azure-deploy/
git commit -m "Update Azure config"
git push origin main
```

### Manual Deployment

1. Go to **Actions → Deploy to Azure**
2. Click **Run workflow**
3. Select action: `deploy` or `destroy`

### Pull Request

PRs to `main` will validate templates but not deploy:

```bash
git checkout -b feature/update-vm-size
# Edit azure-deploy/main.bicep
git push -u origin feature/update-vm-size
```

## Workflow Triggers

| Event | Action |
|-------|--------|
| Push to `main` (azure-deploy files changed) | Deploy |
| PR to `main` (azure-deploy files changed) | Validate only |
| Manual dispatch | Deploy or Destroy |

## Environment Variables

Edit these in the workflow file or GitHub secrets:

```yaml
env:
  AZURE_RG: fabric-rg          # Resource group name
  AZURE_LOCATION: eastus       # Azure region
  VM_NAME: fabric-vm          # VM name
  ADMIN_USERNAME: fabricadmin # VM admin username
```

## Troubleshooting

### Permission Denied
- Verify service principal has Contributor role
- Check OIDC federated credential is configured

### Template Validation Failed
- Run `az bicep build --file azure-deploy/main.bicep` locally

### VM Not Found
- Check resource group exists: `az group show -n fabric-rg`
- Verify VM name matches: `az vm list -g fabric-rg`

## Security Notes

- ✅ Uses OIDC (OpenID Connect) - no secrets in workflow
- ✅ Service principal has minimal permissions
- ⚠️ SSH key is artifact - auto-deletes after 1 day
- ⚠️ Consider using Azure Key Vault for production