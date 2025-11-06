#!/usr/bin/env bash
# Test script to validate Squid proxy configuration
# This script can be run after starting the container to test domain access
set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

proxy_url="http://localhost:3128"

if ! command -v bc >/dev/null; then
    log "bc command not found, please install it."
    exit 1
fi

if ! command -v curl >/dev/null; then
    log "curl command not found, please install it."
    exit 1
fi

# Test domains from our allowed-domains.txt
success_urls=(
    "https://api.github.com"
    "https://maven.apache.org"
    "https://www.schemastore.org"
)

# Test blocked domain (should fail)
blocked_urls=(
    "https://copilot-telemetry.githubusercontent.com"
    "https://westus-0.in.applicationinsights.azure.com"
    "https://telemetry.business.githubcopilot.com"
)

# cached urls
cached_urls=(
    "http://www.microsoft.com/pkiops/crl/Microsoft%20Time-Stamp%20PCA%202010(1).crl"
    "http://crl.microsoft.com/pki/crl/products/MicRooCerAut_2010-06-23.crl"
    "http://crl3.digicert.com/DigiCertTrustedG4RSA4096SHA256TimeStampingCA.crl"
    "http://crl3.digicert.com/DigiCertTrustedG4CodeSigningRSA4096SHA3842021CA1.crl"
)


function test_success_urls() {
    local error_count=0
    log ""
    log "Testing allowed domains through proxy..."
    for success_url in "${success_urls[@]}"; do
        log "Testing $success_url: "
        if curl -s --proxy "$proxy_url" --connect-timeout 5 --max-time 10 -I "$success_url" >/dev/null; then
            log "✅ [$success_url] ACCESSIBLE"
        else
            log "❌ [$success_url] BLOCKED/ERROR"
            error_count=$((error_count + 1))
        fi
        log ""
    done

    return $error_count
}

function test_blocked_urls() {
    local error_count=0

    log "Testing blocked domains (should be blocked)..."
    for blocked_url in "${blocked_urls[@]}"; do
        log "Testing $blocked_url: "
        if curl -s --proxy "$proxy_url" --connect-timeout 5 --max-time 10 -I "$blocked_url" >/dev/null; then
            log "❌ [$blocked_url] ACCESSIBLE (SHOULD BE BLOCKED)"
            error_count=$((error_count + 1))
        else
            log "✅ [$blocked_url] BLOCKED (as expected)"
        fi
        log ""
    done

    return $error_count
}

function test_caching_behavior() {
    local error_count=0
    log "Testing caching behavior..."
    for cached_url in "${cached_urls[@]}"; do
        log "Testing $cached_url for caching..."

        log "First request (should be MISS):"
        response_headers=$(curl -s -v --proxy "$proxy_url" --connect-timeout 5 --max-time 10 -o /dev/null "$cached_url" 2>&1 | grep -i "X-Cache")
        if echo "$response_headers" | grep -q "X-Cache: MISS"; then
            log "✅ [$cached_url] First request was a MISS (as expected)"
        else
            log "❌ [$cached_url] First request was NOT a MISS. Headers: $response_headers"
            error_count=$((error_count + 1))
        fi

        log "Second request (should be HIT):"
        response_headers=$(curl -s -v --proxy "$proxy_url" --connect-timeout 5 --max-time 10 -o /dev/null "$cached_url" 2>&1 | grep -i "X-Cache")
        if echo "$response_headers" | grep -q "X-Cache: HIT"; then
            log "✅ [$cached_url] Second request was a HIT (as expected)"
        else
            log "❌ [$cached_url] Second request was NOT a HIT. Headers: $response_headers"
            error_count=$((error_count + 1))
        fi
        log ""
    done

    return $error_count
}

has_errors=0

if test_success_urls; then
    log "All success URLs passed."
else
    log "Some success URLs failed."
    ((has_errors++))
fi

log ""
if test_blocked_urls; then
    log "All blocked URLs passed."
else
    log "Some blocked URLs failed."
    ((has_errors++))
fi

log ""
if test_caching_behavior; then
    log "Caching behavior test passed."
else
    log "Caching behavior test failed."
    ((has_errors++))
fi

log ""
if [ "$has_errors" -gt 0 ]; then
    log "Healthcheck failed with $has_errors errors."
    exit 1
else
    log "Healthcheck passed successfully."
    exit 0
fi
