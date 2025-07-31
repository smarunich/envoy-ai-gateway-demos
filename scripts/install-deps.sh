#!/bin/bash
set -e

# Install required dependencies (kind, helm, kubectl, docker)
# Usage: ./install-deps.sh <KIND_VERSION>

KIND_VERSION=${1:-"v0.29.0"}

echo "Installing dependencies..."

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Install kind if not present
if ! command -v kind &> /dev/null; then
    echo "Installing kind version ${KIND_VERSION}..."
    # For macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-darwin-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    else
        echo "Unsupported OS: $OSTYPE"
        exit 1
    fi
else
    echo "kind already installed ($(kind version))"
fi

# Install helm if not present
if ! command -v helm &> /dev/null; then
    echo "Installing helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "helm already installed ($(helm version --short))"
fi

# Install kubectl if not present
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "kubectl already installed ($(kubectl version --client --short 2>/dev/null || echo 'kubectl client'))"
fi

echo "Dependencies installation completed!"

# Install jq if not present
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    brew install jq
else
    echo "jq already installed ($(jq --version))"
fi
