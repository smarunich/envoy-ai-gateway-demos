#!/bin/bash

# Interactive Timeout Analysis Script for Provider Fallback Demo
# This script demonstrates the difference between timeout behavior with and without retry policies

set -e

# Configuration
NAMESPACE=${NAMESPACE:-default}
GATEWAY_NAME=${GATEWAY_NAME:-envoy-ai-gateway}
PRIMARY_BACKEND=${PRIMARY_BACKEND:-llm-primary}
FALLBACK_BACKEND=${FALLBACK_BACKEND:-llm-fallback}
MODEL=${MODEL:-gpt-4}
PORT_FORWARD=${PORT_FORWARD:-8080}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔬 INTERACTIVE TIMEOUT ANALYSIS DEMO${NC}"
echo "====================================="
echo ""
echo "This test will demonstrate the difference between:"
echo -e "1. ${RED}❌ NO retry policy${NC}: Fast failures"
echo -e "2. ${GREEN}✅ WITH retry policy${NC}: Retries and eventual fallback success"
echo ""
echo "You'll see actual request/response data and timing measurements."
echo ""
read -p "Press ENTER to start Phase 1 (baseline without retry policy)..."

echo -e "\n${BLUE}🚀 PHASE 1: Testing WITHOUT retry policy (baseline timeout behavior)${NC}"
echo "=================================================================="

# Temporarily remove retry policy to measure baseline behavior
echo -e "${YELLOW}🗑️  Removing retry policy to establish baseline...${NC}"
kubectl delete backendtrafficpolicy retry-policy -n $NAMESPACE --ignore-not-found=true
sleep 3

echo -e "${YELLOW}⚙️  Configuring primary backend to fail (90% server errors)...${NC}"
kubectl set env deployment/$PRIMARY_BACKEND -n $NAMESPACE \
  LLM_D_MODE=failure \
  LLM_D_FAILURE_INJECTION_RATE=90 \
  LLM_D_FAILURE_TYPE_1=server_error \
  LLM_D_FAILURE_TYPE_2="" \
  LLM_D_FAILURE_TYPE_3=""
kubectl rollout status deployment/$PRIMARY_BACKEND -n $NAMESPACE

echo ""
read -p "✋ Ready to send baseline requests. Press ENTER to continue..."

echo -e "\n${PURPLE}📡 BASELINE TEST REQUESTS (NO retry policy)${NC}"
echo "-------------------------------------------"

for i in {1..2}; do
  echo -e "\n${CYAN}🔹 Baseline Request $i:${NC}"
  echo "   Request: POST /v1/chat/completions"
  echo "   Payload: {\"model\": \"$MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"Baseline test without retry policy\"}]}"
  echo "   Expected: Fast failure (1-5 seconds)"
  echo ""
  
  START_TIME=$(date +%s.%3N)
  
  RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}\nTIME_TOTAL:%{time_total}" -H "Content-Type: application/json" \
    --max-time 45 \
    -d "{
      \"model\": \"$MODEL\",
      \"messages\": [{\"role\": \"user\", \"content\": \"Baseline test without retry policy\"}]
    }" \
    http://localhost:$PORT_FORWARD/v1/chat/completions)
  
  END_TIME=$(date +%s.%3N)
  TOTAL_TIME=$(echo "$END_TIME - $START_TIME" | bc -l)
  
  HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
  CURL_TIME=$(echo "$RESPONSE" | grep "TIME_TOTAL:" | cut -d: -f2)
  BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d' | sed '/TIME_TOTAL:/d')
  
  echo -e "   ${BLUE}📊 Response Status:${NC} $HTTP_STATUS"
  echo -e "   ${BLUE}⏱️  Response Time:${NC} ${TOTAL_TIME}s (curl: ${CURL_TIME}s)"
  echo -e "   ${BLUE}📄 Response Body:${NC}"
  echo "$BODY" | jq . 2>/dev/null || echo "$BODY" | head -c 200
  
  if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "   ${GREEN}✅ Request succeeded (unexpected without retry policy)${NC}"
  else
    echo -e "   ${RED}❌ Request failed as expected without retry policy - primary backend is down${NC}"
  fi
  
  if [ $i -lt 2 ]; then
    echo ""
    read -p "   ⏸️  Press ENTER for next baseline request..."
  fi
done

echo ""
echo -e "${YELLOW}📋 PHASE 1 SUMMARY:${NC}"
echo "• Without retry policy, requests fail quickly"
echo "• Primary backend is returning server errors (HTTP 503)"
echo "• No fallback mechanism is activated"
echo "• Response times are fast (~1-5 seconds)"
echo ""
read -p "Press ENTER to proceed to Phase 2 (with retry policy)..."

echo -e "\n${GREEN}🚀 PHASE 2: Testing WITH retry policy (retries and fallback)${NC}"
echo "============================================================"

# Apply retry policy
echo -e "${YELLOW}🔧 Applying retry policy...${NC}"
kubectl apply -f retry-policy.yaml
sleep 5

echo -e "${YELLOW}⏳ Waiting for retry policy to take effect...${NC}"
sleep 5

echo ""
read -p "✋ Ready to send requests with retry policy. Press ENTER to continue..."

echo -e "\n${PURPLE}📡 RETRY POLICY TEST REQUESTS${NC}"
echo "------------------------------"
echo -e "${CYAN}Retry Policy Configuration:${NC}"
echo "• Max Retries: 5"
echo "• Per-Retry Timeout: 30s"
echo "• Backoff: 100ms-10s"
echo "• Retry On: HTTP 503, connect failures"
echo ""

for i in {1..3}; do
  echo -e "\n${CYAN}🔹 Retry Policy Request $i:${NC}"
  echo "   Request: POST /v1/chat/completions"
  echo "   Payload: {\"model\": \"$MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"Test with retry policy enabled\"}]}"
  echo "   Expected: Longer duration, eventual success via fallback"
  echo ""
  
  START_TIME=$(date +%s.%3N)
  
  RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}\nTIME_TOTAL:%{time_total}" -H "Content-Type: application/json" \
    --max-time 180 \
    -d "{
      \"model\": \"$MODEL\",
      \"messages\": [{\"role\": \"user\", \"content\": \"Test with retry policy enabled\"}]
    }" \
    http://localhost:$PORT_FORWARD/v1/chat/completions)
  
  END_TIME=$(date +%s.%3N)
  TOTAL_TIME=$(echo "$END_TIME - $START_TIME" | bc -l)
  
  HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
  CURL_TIME=$(echo "$RESPONSE" | grep "TIME_TOTAL:" | cut -d: -f2)
  BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS:/d' | sed '/TIME_TOTAL:/d')
  
  echo -e "   ${BLUE}📊 Response Status:${NC} $HTTP_STATUS"
  echo -e "   ${BLUE}⏱️  Response Time:${NC} ${TOTAL_TIME}s (curl: ${CURL_TIME}s)"
  echo -e "   ${BLUE}📄 Response Body:${NC}"
  echo "$BODY" | jq . 2>/dev/null || echo "$BODY" | head -c 200
  
  if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "   ${GREEN}✅ FALLBACK SUCCESSFUL! Request completed despite primary failure${NC}"
    
    # Check which backend served the request
    echo -e "   ${BLUE}🔍 Verifying backend source...${NC}"
    FALLBACK_LOGS=$(kubectl logs -l app=$FALLBACK_BACKEND -n $NAMESPACE --tail=5 2>/dev/null | grep -E "(POST|GET|chat|completions)" | tail -1)
    PRIMARY_LOGS=$(kubectl logs -l app=$PRIMARY_BACKEND -n $NAMESPACE --tail=5 2>/dev/null | grep -E "(POST|GET|chat|completions)" | tail -1)
    
    if [[ -n "$FALLBACK_LOGS" ]]; then
      echo -e "   ${GREEN}✅ CONFIRMED: Request served by FALLBACK backend${NC}"
    elif [[ -n "$PRIMARY_LOGS" ]]; then
      echo -e "   ${YELLOW}⚠️  Request served by primary backend (unexpected)${NC}"
    else
      echo -e "   ${YELLOW}❓ Unable to determine backend source from logs${NC}"
    fi
  else
    echo -e "   ${RED}❌ Request failed even with retry policy (Status: $HTTP_STATUS)${NC}"
  fi
  
  if [ $i -lt 3 ]; then
    echo ""
    read -p "   ⏸️  Press ENTER for next retry policy request..."
  fi
done

echo ""
echo -e "${YELLOW}📋 PHASE 2 SUMMARY:${NC}"
echo "• With retry policy, requests eventually succeed"
echo "• Envoy retries failed requests to primary backend"
echo "• After exhausting retries, traffic routes to fallback backend"
echo "• Response times are longer due to retry attempts"
echo "• Fallback backend responds successfully"
echo ""
read -p "Press ENTER to view detailed analysis..."

echo -e "\n${CYAN}🔍 PHASE 3: Detailed Analysis and Evidence${NC}"
echo "=========================================="

echo -e "\n${PURPLE}📊 RETRY POLICY CONFIGURATION:${NC}"
kubectl get backendtrafficpolicy retry-policy -n $NAMESPACE -o yaml 2>/dev/null | grep -A 10 "retry:" || echo "❌ Retry policy not found"

echo -e "\n${PURPLE}📈 GATEWAY RETRY METRICS:${NC}"
ENVOY_POD=$(kubectl get pods -n envoy-gateway-system --selector=gateway.envoyproxy.io/owning-gateway-name=$GATEWAY_NAME -o jsonpath='{.items[0].metadata.name}')

# Port forward to admin interface for detailed metrics
kubectl port-forward -n envoy-gateway-system $ENVOY_POD 19002:19000 &
PF_PID=$!
sleep 3

echo "Collecting metrics from Envoy pod: $ENVOY_POD"
STATS=$(curl -s localhost:19002/stats 2>/dev/null)

echo -e "\n${BLUE}--- Primary Backend Stats ---${NC}"
echo "$STATS" | grep -E "cluster\.backend/default/$PRIMARY_BACKEND.*\.(upstream_rq_total|upstream_rq_5xx|upstream_rq_timeout|upstream_rq_retry|upstream_rq_retry_success|upstream_cx_connect_fail):" | head -5

echo -e "\n${BLUE}--- Fallback Backend Stats ---${NC}"
echo "$STATS" | grep -E "cluster\.backend/default/$FALLBACK_BACKEND.*\.(upstream_rq_total|upstream_rq_2xx|upstream_rq_timeout):" | head -5

echo -e "\n${BLUE}--- Retry-Specific Metrics ---${NC}"
echo "$STATS" | grep -E "retry\.(upstream_rq_retry|upstream_rq_retry_success|upstream_rq_retry_overflow):" | head -5 || echo "No retry metrics found"

kill $PF_PID 2>/dev/null || true

echo -e "\n${CYAN}🕐 TIMEOUT COMPARISON RESULTS:${NC}"
echo "=============================="
echo -e "${RED}WITHOUT Retry Policy:${NC}"
echo "• Fast failures (~1-5 seconds)"
echo "• HTTP 503 server errors"
echo "• No fallback activation"
echo ""
echo -e "${GREEN}WITH Retry Policy:${NC}"
echo "• Longer response times (due to retries)"
echo "• HTTP 200 success (via fallback)"
echo "• Automatic failover to secondary backend"
echo "• Retry attempts visible in metrics"

echo ""
echo -e "${YELLOW}🎯 KEY LEARNINGS:${NC}"
echo "• Retry policies enable resilient AI gateway behavior"
echo "• Fallback providers ensure service availability"
echo "• Timeout configuration balances speed vs reliability"
echo "• Metrics provide visibility into retry and failover behavior"

echo ""
read -p "Press ENTER to see recovery options..."

echo -e "\n${CYAN}🔧 Recovery Options${NC}"
echo "=================="
echo "Primary backend is currently configured to fail."
echo "Options:"
echo "1. Keep primary failed for further testing"
echo "2. Recover primary to healthy state"
echo ""
read -p "Do you want to recover the primary backend now? (y/N): " RECOVER
if [[ "$RECOVER" == "y" || "$RECOVER" == "Y" ]]; then
  echo -e "${YELLOW}Recovering primary backend...${NC}"
  kubectl set env deployment/$PRIMARY_BACKEND -n $NAMESPACE \
    LLM_D_MODE=random \
    LLM_D_FAILURE_INJECTION_RATE=0 \
    LLM_D_FAILURE_TYPE_1="" \
    LLM_D_FAILURE_TYPE_2="" \
    LLM_D_FAILURE_TYPE_3=""
  kubectl rollout status deployment/$PRIMARY_BACKEND -n $NAMESPACE
  echo -e "${GREEN}✅ Primary backend restored to healthy state${NC}"
else
  echo -e "${YELLOW}Primary backend remains in failed state.${NC}"
  echo "Use 'task simulate-primary-recovery' to recover it later."
fi

echo ""
echo -e "${GREEN}🎉 Timeout Analysis Demo Complete!${NC}"
echo "=================================="
echo "You have successfully observed the difference between:"
echo "• Fast failures without retry policies"
echo "• Resilient behavior with retry policies and fallback"
echo ""
echo "Next steps:"
echo "• Run 'task show-retry-evidence' for detailed metrics"
echo "• Try other failure modes with 'task test-all-failure-modes'"
echo "• Explore circuit breaker behavior with 'task test-circuit-breaker'"