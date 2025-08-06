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

1. Navigate to the demo directory:
```bash
cd demos/03-provider-fallback
```

2. Run the complete setup:
```bash
task setup
```

This will:
- Deploy primary and fallback LLM backends
- Configure automatic failover policies
- Set up retry and circuit breaker configurations

3. In a separate terminal, start port forwarding:
```bash
task port-forward
```

4. Test the fallback behavior:
```bash
task test
```

> **Next Steps**: Once you've completed the setup and testing, check out the [Envoy AI Gateway Provider Fallback Guide](https://aigateway.envoyproxy.io/docs/capabilities/traffic/provider-fallback) to learn more about advanced fallback configurations.

## Available Tasks

Run `task` to see all available tasks:

- `task setup` - Complete setup of the demo environment
- `task deploy` - Deploy all components (primary, fallback, and gateway config)
- `task port-forward` - Start port forwarding to access the gateway
- `task test` - Run all test scenarios
- `task test-normal` - Test successful requests through primary provider
- `task test-primary-failure` - Test failover when primary fails
- `task test-bulk-failures` - Send multiple requests to observe fallback behavior
- `task simulate-primary-failure` - Make primary backend return errors
- `task simulate-primary-recovery` - Restore primary backend to healthy state
- `task simulate-primary-slowness` - Make primary backend slow (timeout scenario)
- `task logs` - Show logs from all components
- `task metrics` - Show fallback and retry metrics
- `task status` - Check status of all components
- `task cleanup` - Remove all demo resources

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
- **Latency**: 500ms ± 200ms first token, 50ms ± 20ms inter-token

### Fallback Provider (Stable)
- **Name**: `llm-fallback`
- **Model**: `gpt-4` (same model, different provider)
- **Port**: 8001
- **Mode**: Echo (returns input for reliability)
- **Latency**: 100ms first token, 20ms inter-token
- **Purpose**: Stable backup when primary fails

### Retry Policy
- **Max Retries**: 3 attempts
- **Backoff**: Exponential (1s base, 10s max)
- **Retry On**: 5xx errors, reset, connect-failure
- **Per-Try Timeout**: 10 seconds

### Circuit Breaker
- **Consecutive Errors**: 5 failures trigger circuit open
- **Recovery**: 30-second interval checks
- **Ejection Duration**: 30 seconds

## Testing Scenarios

### Scenario 1: Normal Operation
```bash
task test-normal
```
Sends requests when primary is healthy. All requests should be handled by the primary provider.

### Scenario 2: Primary Provider Failure
```bash
# First, simulate primary failure
task simulate-primary-failure

# Then test the requests
task test-primary-failure
```
Requests automatically failover to the fallback provider after primary returns errors.

### Scenario 3: Primary Provider Timeout
```bash
# Simulate slow responses
task simulate-primary-slowness

# Test timeout and fallback
task test-timeout
```
When primary is slow, requests timeout and retry with fallback provider.

### Scenario 4: Circuit Breaker Activation
```bash
# Send many requests to trigger circuit breaker
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
- Circuit breaker state (open/closed)
- Request distribution between primary and fallback
- Error rates per backend

### Example Metrics Output
```
=== Upstream Metrics ===
Primary Provider (llm-primary):
  Total Requests: 100
  Success Rate: 20%
  Circuit Breaker: OPEN
  
Fallback Provider (llm-fallback):
  Total Requests: 80
  Success Rate: 100%
  Circuit Breaker: CLOSED

=== Retry Metrics ===
Total Retries: 80
Successful After Retry: 80
Failed After All Retries: 0
```

### View Logs
```bash
# All components
task logs

# Just primary provider
task logs-primary

# Just fallback provider
task logs-fallback

# Gateway logs with retry/fallback events
task logs-gateway
```

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

## Advanced Configuration

### Custom Failure Conditions

You can define what constitutes a failure:
```yaml
retryOn:
  - 5xx           # Any 500-level error
  - reset         # Connection reset
  - connect-failure
  - retriable-4xx # Specific 4xx errors
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

- [Provider Fallback Documentation](https://aigateway.envoyproxy.io/docs/capabilities/traffic/provider-fallback)
- [Envoy Retry Policy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#config-http-filters-router-x-envoy-retry-on)
- [Circuit Breaker Pattern](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/circuit_breaking)
- [BackendTrafficPolicy API](https://gateway.envoyproxy.io/docs/api/extension_types/#backendtrafficpolicy)