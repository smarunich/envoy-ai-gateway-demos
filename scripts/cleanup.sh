#!/bin/bash
set -e

# Clean up the kind cluster and resources
# Usage: ./cleanup.sh [CLUSTER_NAME]

CLUSTER_NAME=${1:-"envoy-ai-gateway-demo"}

echo "Cleaning up kind cluster..."

# Delete kind cluster
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Deleting kind cluster: ${CLUSTER_NAME}"
    kind delete cluster --name "${CLUSTER_NAME}"
else
    echo "Kind cluster '${CLUSTER_NAME}' not found"
fi

# Remove task markers
rm -f .task/*

echo "Cleanup completed successfully!"
