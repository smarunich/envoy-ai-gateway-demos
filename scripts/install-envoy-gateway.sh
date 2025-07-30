#!/bin/bash
set -e

# Install Envoy Gateway using Helm
# Usage: ./install-envoy-gateway.sh <ENVOY_GATEWAY_VERSION> <KUBECONFIG_PATH>

ENVOY_GATEWAY_VERSION=${1:-"v0.0.0-latest"}
KUBECONFIG_PATH=${2:-"./kubeconfig.yaml"}

echo "Installing Envoy Gateway ${ENVOY_GATEWAY_VERSION}..."

# Install Envoy Gateway
helm install eg oci://docker.io/envoyproxy/gateway-helm \
    --version "${ENVOY_GATEWAY_VERSION}" \
    -n envoy-gateway-system \
    --create-namespace \
    --kubeconfig="${KUBECONFIG_PATH}"

echo "Waiting for Envoy Gateway to be ready..."
kubectl --kubeconfig="${KUBECONFIG_PATH}" wait --timeout=5m \
    -n envoy-gateway-system deployment/envoy-gateway \
    --for=condition=Available

echo "Envoy Gateway ${ENVOY_GATEWAY_VERSION} installed successfully!"

# Show status
echo "Envoy Gateway pods:"
kubectl --kubeconfig="${KUBECONFIG_PATH}" get pods -n envoy-gateway-system
