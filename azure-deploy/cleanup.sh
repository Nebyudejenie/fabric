#!/bin/bash
# filepath: azure-deploy/cleanup.sh
# Cleanup script to remove Azure resources
# Usage: ./cleanup.sh <resource-group-name>

set -e

RESOURCE_GROUP="${1:-fabric-rg}"

echo "=== Cleaning up Azure resources ==="
echo "Resource Group: $RESOURCE_GROUP"
echo ""

read -p "This will delete all resources in '$RESOURCE_GROUP'. Continue? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo "Deleting resource group..."
az group delete --name "$RESOURCE_GROUP" --yes --no-wait

echo ""
echo "Cleanup complete. Resource group '$RESOURCE_GROUP' is being deleted."
echo "Note: Resources may take a few minutes to fully remove."