#!/bin/bash
set -e

# Clean up the kind cluster and resources
# Usage: ./cleanup.sh <KUBECONFIG_PATH> [CLUSTER_NAME]

KUBECONFIG_PATH=${1:-"./kubeconfig.yaml"}
CLUSTER_NAME=${2:-"envoy-ai-gateway-demo"}

echo "Cleaning up kind cluster..."

# Delete kind cluster
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Deleting kind cluster: ${CLUSTER_NAME}"
    kind delete cluster --name "${CLUSTER_NAME}"
else
    echo "Kind cluster '${CLUSTER_NAME}' not found"
fi

# Remove kubeconfig
if [ -f "${KUBECONFIG_PATH}" ]; then
    echo "Removing kubeconfig: ${KUBECONFIG_PATH}"
    rm -f "${KUBECONFIG_PATH}"
fi

echo "Cleanup completed successfully!"
