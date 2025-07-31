#!/bin/bash
set -e

# Create kind cluster
# Usage: ./create-cluster.sh <CLUSTER_NAME>

CLUSTER_NAME=${1:-"envoy-ai-gateway-demo"}

echo "Creating kind cluster: ${CLUSTER_NAME}"

# Delete existing cluster if it exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Deleting existing cluster: ${CLUSTER_NAME}"
    kind delete cluster --name "${CLUSTER_NAME}"
fi

# Create kind cluster with custom configuration
echo "Creating new kind cluster..."
kind create cluster --name "${CLUSTER_NAME}" 

# Export kubeconfig
echo "Exporting kubeconfig..."
kind export kubeconfig --name "${CLUSTER_NAME}"

# Verify cluster is ready
echo "Verifying cluster status..."
kubectl get nodes

echo "Waiting for all nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "Kind cluster '${CLUSTER_NAME}' created successfully!"
