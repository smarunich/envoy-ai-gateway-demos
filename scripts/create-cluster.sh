#!/bin/bash
set -e

# Create kind cluster
# Usage: ./create-cluster.sh <CLUSTER_NAME> <KUBECONFIG_PATH>

CLUSTER_NAME=${1:-"envoy-ai-gateway-demo"}
KUBECONFIG_PATH=${2:-"./kubeconfig.yaml"}

echo "Creating kind cluster: ${CLUSTER_NAME}"

# Delete existing cluster if it exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "Deleting existing cluster: ${CLUSTER_NAME}"
    kind delete cluster --name "${CLUSTER_NAME}"
fi

# Create kind cluster with custom configuration
echo "Creating new kind cluster..."
cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

# Export kubeconfig
echo "Exporting kubeconfig to: ${KUBECONFIG_PATH}"
kind export kubeconfig --name "${CLUSTER_NAME}" --kubeconfig "${KUBECONFIG_PATH}"

# Verify cluster is ready
echo "Verifying cluster status..."
kubectl --kubeconfig="${KUBECONFIG_PATH}" get nodes

echo "Waiting for all nodes to be ready..."
kubectl --kubeconfig="${KUBECONFIG_PATH}" wait --for=condition=Ready nodes --all --timeout=300s

echo "Kind cluster '${CLUSTER_NAME}' created successfully!"
echo "Kubeconfig saved to: ${KUBECONFIG_PATH}"
