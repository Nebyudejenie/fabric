#!/bin/bash
# filepath: azure-deploy/deploy.sh
# Deployment script for Hyperledger Fabric on Azure Free Tier
# Usage: ./deploy.sh [resource-group-name] [location]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP="${1:-fabric-rg}"
LOCATION="${2:-eastus}"
VM_NAME="fabric-vm"
ADMIN_USERNAME="fabricadmin"

# Convert location to lowercase
LOCATION=$(echo "$LOCATION" | tr '[:upper:]' '[:lower:]')

echo -e "${GREEN}=== Hyperledger Fabric Azure Deployment ===${NC}"
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo ""

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    if ! command -v az &> /dev/null; then
        echo -e "${RED}Error: Azure CLI (az) is not installed${NC}"
        echo "Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed${NC}"
        echo "Install: sudo apt-get install jq"
        exit 1
    fi
    
    echo -e "${GREEN}Prerequisites OK${NC}"
}

# Login to Azure
azure_login() {
    echo -e "${YELLOW}Logging in to Azure...${NC}"
    az account show > /dev/null 2>&1 || az login
    az account set --subscription "$(az account show --query 'id' -o tsv)"
}

# Create resource group
create_resource_group() {
    echo -e "${YELLOW}Creating resource group: $RESOURCE_GROUP${NC}"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table
}

# Generate SSH key if not exists
setup_ssh_key() {
    SSH_KEY_PATH="$HOME/.ssh/azure_fabric_id_rsa"
    
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo -e "${YELLOW}Generating SSH key...${NC}"
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "fabric-azure"
        echo -e "${GREEN}SSH key generated at: $SSH_KEY_PATH${NC}"
    else
        echo -e "${GREEN}Using existing SSH key${NC}"
    fi
    
    SSH_PUBLIC_KEY=$(cat "${SSH_KEY_PATH}.pub")
    echo "$SSH_PUBLIC_KEY" > .ssh_public_key.txt
}

# Deploy Bicep template
deploy_bicep() {
    echo -e "${YELLOW}Deploying Azure resources...${NC}"
    
    # Create parameters file with SSH key
    cat > parameters-deploy.json <<EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "value": "$LOCATION"
    },
    "vmName": {
      "value": "$VM_NAME"
    },
    "adminUsername": {
      "value": "$ADMIN_USERNAME"
    },
    "sshPublicKey": {
      "value": "$(cat .ssh_public_key.txt)"
    },
    "vmSize": {
      "value": "Standard_B1s"
    }
  }
}
EOF

    az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --template-file main.bicep \
        --parameters @parameters-deploy.json \
        --output table
    
    rm -f parameters-deploy.json
}

# Get deployment outputs
get_outputs() {
    echo -e "${YELLOW}Getting deployment outputs...${NC}"
    
    PUBLIC_IP=$(az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" --query 'publicIps' -o tsv)
    
    echo ""
    echo -e "${GREEN}=== Deployment Complete ===${NC}"
    echo "Public IP: $PUBLIC_IP"
    echo "SSH Command: ssh $ADMIN_USERNAME@$PUBLIC_IP"
    echo ""
    echo "Next steps:"
    echo "1. SSH into the VM: ssh $ADMIN_USERNAME@$PUBLIC_IP"
    echo "2. Install Docker:"
    echo "   curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "   sudo sh get-docker.sh"
    echo "   sudo usermod -aG docker $ADMIN_USERNAME"
    echo "3. Copy docker-compose.yaml to VM and run:"
    echo "   sudo docker-compose up -d"
}

# Main execution
main() {
    check_prerequisites
    azure_login
    create_resource_group
    setup_ssh_key
    deploy_bicep
    get_outputs
}

main "$@"