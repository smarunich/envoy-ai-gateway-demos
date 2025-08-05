# Getting Started with Envoy AI Gateway

This demo showcases the Envoy AI Gateway using the LLM-D Inference Simulator as a mock backend. The LLM-D Inference Simulator provides a lightweight way to test AI workloads without running actual LLM inference, making it perfect for development and testing scenarios.

## Overview

This demo sets up:
- **Envoy AI Gateway** with custom configuration for AI workloads
- **LLM-D Inference Simulator** as the AI backend (using `qwen3` model in echo mode)
- **Kubernetes services and routes** for AI API endpoints
- **Automated tasks** for easy deployment and testing

## Prerequisites

- `kubectl` configured to access your cluster
- `task` (Taskfile) installed ([installation guide](https://taskfile.dev/installation/))
- `jq` for JSON pretty-printing (optional but recommended)

## Quick Start

1. Navigate to the demo directory:
```bash
cd demos/01-getting-started
```

2. Run the complete setup:
```bash
task setup
```

This will:
- Check prerequisites
- Deploy all components
- Wait for everything to be ready

3. In a separate terminal, start port forwarding:
```bash
task port-forward
```

4. Test the gateway:
```bash
task test
```

> **Next Steps**: Once you've completed the setup and testing, check out the [Envoy AI Gateway Basic Usage Guide](https://aigateway.envoyproxy.io/docs/getting-started/basic-usage) to learn more about features and configuration options.

## Available Tasks

Run `task` to see all available tasks:

- `task setup` - Complete setup of the demo environment
- `task deploy` - Deploy the configuration to Kubernetes
- `task port-forward` - Start port forwarding to access the gateway
- `task test` - Run all test endpoints
- `task test-chat` - Test chat completions endpoint
- `task test-embeddings` - Test embeddings endpoint
- `task test-models` - Test models endpoint
- `task test-stream` - Test streaming chat completions
- `task logs` - Show logs from all components
- `task status` - Check status of all components
- `task cleanup` - Remove all demo resources

## Architecture

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────────────┐
│   Client    │────▶│  Envoy AI       │────▶│  LLM-D Inference    │
│             │     │  Gateway        │     │  Simulator (qwen3)  │
└─────────────┘     └─────────────────┘     └──────────────────────┘
                           │
                           ▼
                    ┌─────────────────┐
                    │  Route matching │
                    │  x-ai-eg-model  │
                    └─────────────────┘
```

## Configuration Details

### Gateway Configuration
- **Gateway Name**: `envoy-ai-gateway`
- **Listener**: HTTP on port 80
- **Namespace**: `default`
- **Buffer Limit**: Configured for AI workloads

### LLM-D Inference Simulator
- **Mode**: Echo mode (returns the input text)
- **Model**: `qwen3`
- **Port**: 8000
- **Endpoints**: `/v1/chat/completions`, `/v1/embeddings`, `/v1/models`
- **Performance**: 
  - Time to first token: 10ms
  - Inter-token latency: 20ms
- **Resources**: 128Mi memory, 100m CPU

### Routing
Routes are matched based on the `x-ai-eg-model` header:
- Value: `qwen3`

## Testing Examples

### Chat Completions
```bash
curl -H "Content-Type: application/json" \
     -H "x-ai-eg-model: qwen3" \
     -d '{
       "model": "qwen3",
       "messages": [{"role": "user", "content": "Hello, world!"}]
     }' \
     http://localhost:8080/v1/chat/completions
```

### Embeddings
```bash
curl -H "Content-Type: application/json" \
     -H "x-ai-eg-model: qwen3" \
     -d '{
       "model": "qwen3",
       "input": "Test embedding text"
     }' \
     http://localhost:8080/v1/embeddings
```

### Streaming Response
```bash
curl -H "Content-Type: application/json" \
     -H "x-ai-eg-model: qwen3" \
     -d '{
       "model": "qwen3",
       "messages": [{"role": "user", "content": "Stream this"}],
       "stream": true
     }' \
     http://localhost:8080/v1/chat/completions
```

## Troubleshooting

### Port Forward Issues
If you can't connect to the gateway:
1. Check that port-forward is running
2. Verify the Envoy service exists: `task status`
3. Check gateway logs: `task logs-gateway`

### Simulator Not Responding
1. Check simulator logs: `task logs-simulator`
2. Verify pod is running: `kubectl get pods -l app=llm-d-inference-sim`
3. Restart if needed: `task restart`

### Gateway Not Ready
The gateway may take a few moments to become ready. You can:
1. Check status: `kubectl get gateway -n default`
2. View events: `kubectl describe gateway envoy-ai-gateway`

## Cleanup

To remove all demo resources:
```bash
task cleanup
```

## Next Steps

After getting familiar with this basic setup, you can:
1. Modify the simulator configuration for different response modes
2. Add additional routes and backends
3. Configure authentication and rate limiting
4. Replace the simulator with a real LLM backend

## References

- [Envoy AI Gateway Documentation](https://aigateway.envoyproxy.io/)
- [LLM-D Inference Simulator](https://llm-d.ai/docs/architecture/Components/inference-sim)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
