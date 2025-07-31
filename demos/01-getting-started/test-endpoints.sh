#!/bin/bash

# Test script for Envoy AI Gateway with LLM Infinity Simulator

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Gateway URL
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8080}"
MODEL_HEADER="x-ai-eg-model: llm-infinity-simulator"

echo -e "${YELLOW}Testing Envoy AI Gateway with LLM Infinity Simulator${NC}"
echo -e "Gateway URL: ${GATEWAY_URL}\n"

# Function to test endpoint
test_endpoint() {
    local name=$1
    local endpoint=$2
    local data=$3
    
    echo -e "${YELLOW}Testing ${name}...${NC}"
    
    response=$(curl -s -w "\n%{http_code}" -H "Content-Type: application/json" \
        -H "${MODEL_HEADER}" \
        -d "${data}" \
        "${GATEWAY_URL}${endpoint}" 2>/dev/null || true)
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ ${name} test passed (HTTP ${http_code})${NC}"
        echo "$body" | jq . 2>/dev/null || echo "$body"
    else
        echo -e "${RED}✗ ${name} test failed (HTTP ${http_code})${NC}"
        echo "$body"
    fi
    echo ""
}

# Test models endpoint
echo -e "${YELLOW}Testing Models endpoint...${NC}"
response=$(curl -s -w "\n%{http_code}" -H "${MODEL_HEADER}" \
    "${GATEWAY_URL}/v1/models" 2>/dev/null || true)

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Models test passed (HTTP ${http_code})${NC}"
    echo "$body" | jq . 2>/dev/null || echo "$body"
else
    echo -e "${RED}✗ Models test failed (HTTP ${http_code})${NC}"
    echo "$body"
fi
echo ""

# Test chat completions
test_endpoint "Chat Completions" "/v1/chat/completions" '{
    "model": "llm-infinity-test-model",
    "messages": [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Hello! This is a test message."}
    ],
    "temperature": 0.7,
    "max_tokens": 100
}'

# Test embeddings
test_endpoint "Embeddings" "/v1/embeddings" '{
    "model": "llm-infinity-test-model",
    "input": "This is a test text for embeddings generation."
}'

# Test streaming chat completions
echo -e "${YELLOW}Testing Streaming Chat Completions...${NC}"
echo -e "Sending streaming request..."

curl -s -N -H "Content-Type: application/json" \
    -H "${MODEL_HEADER}" \
    -d '{
        "model": "llm-infinity-test-model",
        "messages": [{"role": "user", "content": "Tell me a short story in streaming mode."}],
        "stream": true,
        "max_tokens": 50
    }' \
    "${GATEWAY_URL}/v1/chat/completions" 2>/dev/null | head -n 5

echo -e "\n${GREEN}✓ Streaming test completed (showing first 5 lines)${NC}\n"

# Test with missing model header (should fail)
echo -e "${YELLOW}Testing without required header (should fail)...${NC}"
response=$(curl -s -w "\n%{http_code}" -H "Content-Type: application/json" \
    -d '{"model": "test", "messages": [{"role": "user", "content": "test"}]}' \
    "${GATEWAY_URL}/v1/chat/completions" 2>/dev/null || true)

http_code=$(echo "$response" | tail -n1)
if [ "$http_code" != "200" ]; then
    echo -e "${GREEN}✓ Request correctly rejected without proper header (HTTP ${http_code})${NC}"
else
    echo -e "${RED}✗ Request should have been rejected${NC}"
fi

echo -e "\n${GREEN}All tests completed!${NC}"