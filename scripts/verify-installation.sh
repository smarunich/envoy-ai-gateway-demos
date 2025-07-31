#!/bin/bash
set -e

# Verify the installation status
# Usage: ./verify-installation.sh

echo "=== Cluster Status ==="
kubectl get nodes

echo -e "\n=== Envoy Gateway Pods ==="
kubectl get pods -n envoy-gateway-system

echo -e "\n=== Envoy AI Gateway Pods ==="
kubectl get pods -n envoy-ai-gateway-system

echo -e "\n=== Gateway Classes ==="
kubectl get gatewayclasses

echo -e "\n=== Gateways ==="
kubectl get gateways -A

echo -e "\n=== Services ==="
kubectl get services -A

echo -e "\n=== Installation Verification Complete ==="
