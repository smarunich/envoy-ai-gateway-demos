# Envoy AI Gateway Demos Repository

This repository contains a comprehensive Taskfile for setting up and managing an Envoy AI Gateway demonstration environment on kind (Kubernetes in Docker).

# Prerequisites

- Taskfile
   ```bash
   sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d
   ```
- kind
- kubectl
- helm
- jq

## Quick Start

To set up the complete environment with one command:

```bash
task setup-all
```

This will:
1. Install dependencies (kind, helm, kubectl)
2. Create a kind cluster
3. Install Envoy Gateway (v0.0.0-latest)
4. Install Envoy AI Gateway (v0.0.0-latest)
5. Configure AI Gateway integration
6. Install quickstart examples
7. Verify the installation

## Available Tasks

View all available tasks:
```bash
task --list
```

### Core Tasks

- `task setup-all` - Complete setup from scratch
- `task create-cluster` - Create kind cluster only
- `task install-envoy-gateway` - Install Envoy Gateway
- `task install-envoy-ai-gateway` - Install Envoy AI Gateway
- `task verify-installation` - Check installation status

### Status & Monitoring Tasks

- `task --status <task-name>` - Use Task's native status check directly

### Utility Tasks

- `task cleanup` - Remove k3s cluster and cleanup
- `task logs-envoy-gateway` - View Envoy Gateway logs
- `task logs-ai-gateway` - View AI Gateway logs
- `task port-forward` - Port forward to access gateway (localhost:8080)
- `task verify-installation` - Verify installation status

## Configuration

The setup uses the following default configurations:

- **Cluster Name**: `envoy-ai-gateway-demo`
- **Kind Version**: `v0.29.0`
- **Envoy Gateway Version**: `v0.0.0-latest` (latest development)
- **Envoy AI Gateway Version**: `v0.0.0-latest` (latest development)
- **Kubeconfig**: `./kubeconfig.yaml`

You can modify these in the `vars` section of the Taskfile.yml.

## Components Installed

### Envoy Gateway
- **Version**: v0.0.0-latest
- **Namespace**: `envoy-gateway-system`
- **Installation**: Helm chart from `oci://docker.io/envoyproxy/gateway-helm`

### Envoy AI Gateway
- **Version**: v0.0.0-latest
- **Namespace**: `envoy-ai-gateway-system`
- **Installation**: Helm chart from `oci://docker.io/envoyproxy/ai-gateway-helm`

### Additional Components
- Redis (for rate limiting)
- RBAC configurations
- Gateway API CRDs
- Quickstart example application

## Usage Examples

### Basic Setup
```bash
# Complete setup
task setup-all

# Check status
task verify-installation

# Access the gateway
task port-forward
```

### Development Workflow
```bash
# Create cluster
task create-cluster

# Install components step by step
task install-envoy-gateway
task install-envoy-ai-gateway

# Check logs
task logs-envoy-gateway
task logs-ai-gateway
```

### Cleanup
```bash
# Remove everything
task cleanup
```

## Accessing the Gateway

After installation, you can access the gateway in several ways:

```bash
task port-forward
```

## Troubleshooting

### Check Installation Status
```bash
task verify-installation
```

### View Logs
```bash
# Envoy Gateway logs
task logs-envoy-gateway

# AI Gateway logs
task logs-ai-gateway
```


### Manual Verification
```bash
# Check all pods
kubectl --kubeconfig=./kubeconfig.yaml get pods -A

# Check gateway classes
kubectl --kubeconfig=./kubeconfig.yaml get gatewayclasses

# Check gateways
kubectl --kubeconfig=./kubeconfig.yaml get gateways -A
```

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client App    │───▶│  Envoy Gateway   │───▶│   AI Services   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │ Envoy AI Gateway │
                       │   (Controller)   │
                       └──────────────────┘
```

## Next Steps

After successful installation:

1. **Explore AI Gateway Features**: Check the [Envoy AI Gateway documentation](https://aigateway.envoyproxy.io/docs/getting-started/basic-usage)
2. **Connect AI Providers**: Configure OpenAI, AWS Bedrock, or other AI services
3. **Test Rate Limiting**: Experiment with the built-in rate limiting features
4. **Custom Configurations**: Modify gateway policies and routing rules

## Contributing

Feel free to submit issues and enhancement requests!

## Resources

- [Envoy Gateway Documentation](https://gateway.envoyproxy.io/)
- [Envoy AI Gateway Documentation](https://aigateway.envoyproxy.io/)
