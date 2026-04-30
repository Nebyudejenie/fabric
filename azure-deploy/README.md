# Azure Free Tier Deployment for Hyperledger Fabric

> ⚠️ **Warning**: Azure Free Tier has very limited resources (1 vCPU, 1GB RAM). This setup is for **development and testing only** — not production use.

## Overview

This directory contains Azure Bicep templates and scripts to deploy a minimal Hyperledger Fabric network on Azure Free Tier.

### Architecture

```
┌─────────────────────────────────────┐
│         Azure VM (B1s)              │
│  ┌─────────┐ ┌─────────┐ ┌───────┐ │
│  │   CA    │ │ Orderer │ │ Peer  │ │
│  │ :7054   │ │ :7050   │ │:7051  │ │
│  └─────────┘ └─────────┘ └───────┘ │
└─────────────────────────────────────┘
```

## Prerequisites

- Azure CLI (`az`) — [Install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- jq (`sudo apt-get install jq`)
- Azure subscription with Free Tier credits

## Quick Start

### 1. Login to Azure

```bash
az login
az account set --subscription "your-subscription-id"
```

### 2. Deploy

```bash
cd azure-deploy
chmod +x deploy.sh cleanup.sh
./deploy.sh fabric-rg eastus
```

### 3. Connect via SSH

```bash
ssh fabricadmin@<PUBLIC_IP>
```

### 4. Install Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $ADMIN_USERNAME
exit  # Re-login to apply group changes
ssh fabricadmin@<PUBLIC_IP>
```

### 5. Start Fabric Network

```bash
sudo docker-compose -f docker-compose.yaml up -d
```

## Files

| File | Description |
|------|-------------|
| `main.bicep` | Azure infrastructure template |
| `deploy.sh` | Main deployment script |
| `cleanup.sh` | Resource cleanup script |
| `docker-compose.yaml` | Fabric network containers |
| `parameters.json` | Deployment parameters template |

## Port Reference

| Service | Port | Protocol |
|---------|------|----------|
| CA | 7054 | HTTPS |
| Orderer | 7050 | gRPC |
| Peer | 7051 | gRPC |

## Costs

- **Azure Free Tier**: ~$0/month (within 750 hours)
- **After credits**: ~$25-35/month for B1s VM

## Cleanup

```bash
./cleanup.sh fabric-rg
```

## Limitations

- Single VM = no high availability
- Solo orderer = not fault-tolerant
- Limited resources = slow transaction processing
- No Kubernetes = manual container management

## Next Steps

1. [Fabric Getting Started](https://hyperledger-fabric.readthedocs.io/)
2. [Azure VM pricing](https://azure.microsoft.com/pricing/calculator/)