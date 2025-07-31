#!/bin/bash
set -e

# Install Envoy Gateway using Helm
# Usage: ./install-envoy-gateway.sh <ENVOY_GATEWAY_VERSION>

ENVOY_GATEWAY_VERSION=${1:-"v0.0.0-latest"}

echo "Installing Envoy Gateway ${ENVOY_GATEWAY_VERSION}..."

# Install Envoy Gateway
helm install eg oci://docker.io/envoyproxy/gateway-helm \
    --version "${ENVOY_GATEWAY_VERSION}" \
    -n envoy-gateway-system \
    --create-namespace

echo "Waiting for Envoy Gateway to be ready..."
kubectl wait --timeout=5m \
    -n envoy-gateway-system deployment/envoy-gateway \
    --for=condition=Available

echo "Envoy Gateway ${ENVOY_GATEWAY_VERSION} installed successfully!"

# Show status
echo "Envoy Gateway pods:"
kubectl get pods -n envoy-gateway-system
