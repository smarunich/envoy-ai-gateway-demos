# Provider Fallback with Envoy AI Gateway

This demo showcases automatic provider fallback capabilities, demonstrating how the Envoy AI Gateway handles failures from primary AI providers by seamlessly switching to backup providers without disrupting service.

## Overview

This demo sets up:
- **Primary AI Provider** (simulating an unreliable service with intermittent failures)
- **Fallback AI Provider** (stable backup service)
- **Automatic failover** when the primary provider returns errors or times out
- **Smart retry policies** with exponential backoff
- **Health-based routing** to avoid unhealthy backends

## Prerequisites

- `kubectl` configured to access your cluster
- `task` (Taskfile) installed ([installation guide](https://taskfile.dev/installation/))
- `jq` for JSON pretty-printing (optional but recommended)

## Quick Start

1. **Setup the demo environment:**
```bash
cd demos/03-provider-fallback
task setup
```

2. **Test normal operation (both providers healthy):**
```bash
task test-normal
```

3. **Test provider fallback behavior:**
```bash
task test-primary-failure
```

4. **View logs to see failover in action:**
```bash
task logs
```

5. **Check metrics to validate retry/fallback behavior:**
```bash
task metrics
```

## Core Workflow

### 1. Setup
```bash
task setup
```
Deploys primary and fallback LLM providers with retry policies and starts port forwarding.

### 2. Test Normal Operation  
```bash
task test-normal
```
Verifies requests work when both providers are healthy. All traffic should route to the primary provider.

### 3. Test Failover Behavior
```bash
task test-primary-failure
```
**Interactive demo** that:
- Removes retry policy and shows fast failures (baseline)
- Applies retry policy and demonstrates successful fallback
- Provides detailed timing analysis and metrics
- Includes recovery options

### 4. View Logs
```bash
task logs                 # All component logs
task logs-primary         # Primary provider logs  
task logs-fallback        # Fallback provider logs
task logs-gateway         # Gateway retry/fallback events
```

### 5. Check Metrics
```bash
task metrics              # Retry and fallback statistics
task show-retry-evidence  # Detailed retry evidence and analysis
```

## Architecture

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────────────┐
│   Client    │────▶│  Envoy AI       │────▶│  Primary Provider   │
│             │     │  Gateway        │     │  (llm-primary)      │
└─────────────┘     └─────────────────┘     └──────────────────────┘
                           │                            ❌ (on failure)
                           │                            │
                           ▼                            ▼
                    ┌─────────────────┐     ┌──────────────────────┐
                    │  Retry & Route  │────▶│  Fallback Provider  │
                    │  Selection      │     │  (llm-fallback)     │
                    └─────────────────┘     └──────────────────────┘
```

## Configuration Details

### Primary Provider (Unreliable)
- **Name**: `llm-primary`
- **Model**: `gpt-4`
- **Behavior**: Simulated with variable latency and random responses
- **Port**: 8000
- **Mode**: Random (returns varied responses)
- **Latency**: 500ms ± 100ms first token, 50ms ± 10ms inter-token

### Fallback Provider (Stable)
- **Name**: `llm-fallback`
- **Model**: `gpt-4` (same model, different provider)
- **Port**: 8001
- **Mode**: Echo (returns input for reliability)
- **Latency**: 100ms first token, 20ms inter-token
- **Purpose**: Stable backup when primary fails

### Retry Policy
- **Max Retries**: 5 attempts
- **Backoff**: Exponential (100ms base, 10s max)
- **Retry On**: 503 errors, connect-failure
- **Per-Try Timeout**: 30 seconds

## How It Works

1. **Initial Request**: Client sends request to Envoy AI Gateway

2. **Primary Attempt**: Gateway routes to primary provider first

3. **Failure Detection**: If primary returns error or times out:
   - Gateway marks the attempt as failed
   - Updates circuit breaker statistics

4. **Automatic Retry**: Based on retry policy:
   - Waits with exponential backoff
   - Routes to next available backend (fallback)

5. **Circuit Breaker**: After consecutive failures:
   - Opens circuit to primary provider
   - All traffic goes directly to fallback
   - Periodically checks if primary recovered

6. **Response**: Client receives response from whichever provider succeeded

## Testing Scenarios

### Scenario 1: Normal Operation
```bash
task test-normal
```
Sends requests when primary is healthy. All requests should be handled by the primary provider.

### Scenario 2: Primary Provider Failure
```bash
task test-primary-failure
```
**Interactive demo** that shows:
- Phase 1: Fast failures without retry policy (baseline)
- Phase 2: Successful fallback with retry policy
- Phase 3: Detailed metrics and analysis

### Scenario 3: Specific Failure Types
```bash
# Simulate different error scenarios
task simulate-rate-limit-failure       # HTTP 429 errors
task simulate-auth-failure             # HTTP 401 errors  
task simulate-server-error-failure     # HTTP 503 errors
task simulate-mixed-failures           # Random error types

# Then test the fallback behavior
task test-<failure-type>-fallback
```

### Scenario 4: Circuit Breaker Activation
```bash
task test-circuit-breaker
```
After consecutive failures, circuit breaker opens and all traffic goes directly to fallback.

## Monitoring Fallback Behavior

### View Real-time Metrics
```bash
task metrics
```

This shows:
- Retry attempts and success rates
- Circuit breaker state
- Request distribution between primary and fallback
- Error rates per backend

### Example Metrics Output
```
=== Upstream Metrics ===
Primary Provider (llm-primary):
  upstream_rq_total: 100
  upstream_rq_5xx: 80
  upstream_rq_retry: 80
  
Fallback Provider (llm-fallback):
  upstream_rq_total: 80
  upstream_rq_2xx: 80

=== Retry Metrics ===
upstream_rq_retry_success: 80
```

### View Logs
```bash
task logs                 # All component logs
task logs-primary         # Primary provider logs  
task logs-fallback        # Fallback provider logs
task logs-gateway         # Gateway retry/fallback events
```

## Optional Tasks

Beyond the core workflow, additional tasks are available for advanced testing:

### Extended Testing
```bash
task test                           # Run all test scenarios
task test-bulk-failures            # Send multiple requests
task test-timeout                  # Test timeout scenarios  
task test-circuit-breaker          # Test circuit breaker activation
task test-all-failure-modes        # Test all failure types sequentially
```

### Individual Failure Type Testing
```bash
task test-rate-limit-fallback       # Test rate limit → fallback
task test-auth-failure-fallback     # Test auth error → fallback
task test-context-length-fallback   # Test context length → fallback
task test-server-error-fallback     # Test server error → fallback
task test-model-not-found-fallback  # Test model not found → fallback
task test-mixed-failures-fallback   # Test mixed errors → fallback
```

### Status and Monitoring
```bash
task status                         # Check all component status
task test-primary-health           # Health check primary provider
task port-forward                  # Start port forwarding manually
task stop-port-forward             # Stop port forwarding
```

### Configuration Management
```bash
task deploy                        # Deploy components only (no setup)
task wait-ready                    # Wait for components to be ready
task show-config                   # Display applied configurations
```

## Advanced Configuration

### Custom Failure Conditions

You can define what constitutes a failure:
```yaml
retryOn:
  httpStatusCodes:
    - 503           # Service unavailable
    - 502           # Bad gateway
    - 500           # Internal server error
  triggers:
    - reset         # Connection reset
    - connect-failure
    - retriable-status-codes
```

### Weighted Routing

Configure traffic distribution when both providers are healthy:
```yaml
backendRefs:
  - name: primary-backend
    weight: 80    # 80% of traffic
  - name: fallback-backend
    weight: 20    # 20% of traffic
```

### Health Checking

Configure active health checks:
```yaml
healthCheck:
  interval: 10s
  timeout: 3s
  unhealthyThreshold: 3
  healthyThreshold: 2
  path: /v1/models
```

## Troubleshooting

### Fallback Not Working
1. Check both providers are running: `task status`
2. Verify retry policy is applied: `kubectl get backendtrafficpolicy`
3. Check gateway logs for retry attempts: `task logs-gateway`

### All Requests Going to Fallback
1. Check primary provider health: `task test-primary-health`
2. Circuit breaker may be open: `task metrics`
3. Reset primary to healthy: `task simulate-primary-recovery`

### Slow Response Times
1. Check if retries are happening: `task metrics`
2. Reduce per-try timeout if needed
3. Consider adjusting backoff parameters

## Cleanup

To remove all demo resources:
```bash
task cleanup
```

## Next Steps

After exploring this demo, you can:
1. Configure multiple fallback providers in priority order
2. Implement geographic-based fallback
3. Add custom health checks for providers
4. Configure different retry policies per model
5. Integrate with monitoring systems for alerts

## References

- [Envoy AI Gateway Provider Fallback Guide](https://aigateway.envoyproxy.io/docs/capabilities/traffic/provider-fallback)
- [Envoy Retry Policy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#config-http-filters-router-x-envoy-retry-on)
- [Circuit Breaker Pattern](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/circuit_breaking)
- [BackendTrafficPolicy API](https://gateway.envoyproxy.io/docs/api/extension_types/#backendtrafficpolicy)
- [LLM-D Inference Simulator](https://github.com/llm-d/llm-d-inference-sim)