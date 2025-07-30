#!/bin/bash
set -e

# Verify the installation status
# Usage: ./verify-installation.sh <KUBECONFIG_PATH>

KUBECONFIG_PATH=${1:-"./kubeconfig.yaml"}

echo "=== Cluster Status ==="
kubectl --kubeconfig="${KUBECONFIG_PATH}" get nodes

echo -e "\n=== Envoy Gateway Pods ==="
kubectl --kubeconfig="${KUBECONFIG_PATH}" get pods -n envoy-gateway-system

echo -e "\n=== Envoy AI Gateway Pods ==="
kubectl --kubeconfig="${KUBECONFIG_PATH}" get pods -n envoy-ai-gateway-system

echo -e "\n=== Gateway Classes ==="
kubectl --kubeconfig="${KUBECONFIG_PATH}" get gatewayclasses

echo -e "\n=== Gateways ==="
kubectl --kubeconfig="${KUBECONFIG_PATH}" get gateways -A

echo -e "\n=== Services ==="
kubectl --kubeconfig="${KUBECONFIG_PATH}" get services -A

echo -e "\n=== Installation Verification Complete ==="
