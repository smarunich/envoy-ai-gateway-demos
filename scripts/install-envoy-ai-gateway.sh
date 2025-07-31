#!/bin/bash
set -e

# Install Envoy AI Gateway using Helm
# Usage: ./install-envoy-ai-gateway.sh <ENVOY_AI_GATEWAY_VERSION>

ENVOY_AI_GATEWAY_VERSION=${1:-"v0.0.0-latest"}

echo "Installing Envoy AI Gateway ${ENVOY_AI_GATEWAY_VERSION}..."

# Install Envoy AI Gateway
helm upgrade -i aieg oci://docker.io/envoyproxy/ai-gateway-helm \
    --version "${ENVOY_AI_GATEWAY_VERSION}" \
    --namespace envoy-ai-gateway-system \
    --create-namespace

echo "Waiting for AI Gateway controller to be ready..."
kubectl wait --timeout=2m \
    -n envoy-ai-gateway-system deployment/ai-gateway-controller \
    --for=condition=Available

echo "Envoy AI Gateway ${ENVOY_AI_GATEWAY_VERSION} installed successfully!"

# Show status
echo "Envoy AI Gateway pods:"
kubectl get pods -n envoy-ai-gateway-system


echo "Applying AI Gateway configuration to Envoy Gateway..."

# Apply Redis configuration (for rate limiting)
echo "Applying Redis configuration..."
kubectl apply -f \
    https://raw.githubusercontent.com/envoyproxy/ai-gateway/main/manifests/envoy-gateway-config/redis.yaml

# Apply AI Gateway configuration
echo "Applying AI Gateway configuration..."
kubectl apply -f \
    https://raw.githubusercontent.com/envoyproxy/ai-gateway/main/manifests/envoy-gateway-config/config.yaml

# Apply RBAC configuration
echo "Applying RBAC configuration..."
kubectl apply -f \
    https://raw.githubusercontent.com/envoyproxy/ai-gateway/main/manifests/envoy-gateway-config/rbac.yaml

# Restart Envoy Gateway deployment
echo "Restarting Envoy Gateway deployment..."
kubectl rollout restart \
    -n envoy-gateway-system deployment/envoy-gateway

# Wait for Envoy Gateway to be ready after restart
echo "Waiting for Envoy Gateway to be ready after restart..."
kubectl wait --timeout=2m \
    -n envoy-gateway-system deployment/envoy-gateway \
    --for=condition=Available

echo "AI Gateway configuration applied successfully!"

# Show status
echo "Envoy Gateway pods after configuration:"
kubectl get pods -n envoy-gateway-system
