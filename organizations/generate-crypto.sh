#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
######################################################################
# generate-crypto.sh - Generate CA and MSP certificates
# Usage: ./generate-crypto.sh
######################################################################

set -e

# Configuration
OUTPUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FABRIC_ROOT="$(cd "$OUTPUT_DIR/.." && pwd)"

# Check if cryptogen is available
if ! command -v cryptogen &> /dev/null; then
    echo "Error: cryptogen not found in PATH"
    echo "Please build Fabric or add bin/ to PATH"
    exit 1
fi

echo "=========================================="
echo "Generating Crypto Materials"
echo "=========================================="

# Clean up existing crypto materials
echo "Cleaning existing crypto materials..."
rm -rf "$OUTPUT_DIR/peerOrganizations"
rm -rf "$OUTPUT_DIR/ordererOrganizations"

# Generate peer organizations
echo ""
echo "Generating Org1..."
cryptogen generate --config="$OUTPUT_DIR/crypto-config.yaml" --output="$OUTPUT_DIR"

echo ""
echo "=========================================="
echo "Crypto materials generated successfully!"
echo "=========================================="
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "Structure created:"
echo "  - peerOrganizations/"
echo "    - org1.example.com/"
echo "      - ca/"
echo "      - tlsca/"
echo "      - msp/"
echo "      - peers/"
echo "      - users/"
echo "    - org2.example.com/"
echo "      - (same structure)"
echo "  - ordererOrganizations/"
echo "    - example.com/"
echo "      - (same structure)"
echo ""
echo "Next steps:"
echo "  1. Review and update configtx.yaml"
echo "  2. Generate genesis block: configtxgen -profile ChannelDefaults -outputBlock genesis.block"
echo "  3. Create channel: configtxgen -profile SampleAppChannel -outputCreateChannelTx channel.tx"
echo "=========================================="