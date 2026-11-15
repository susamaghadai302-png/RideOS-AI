#!/usr/bin/env bash
# ==============================================================================
# RideOS AI — Automated Staged Canary Rollout & Rollback Controller
# ==============================================================================
# Controlled traffic progression: 1% -> 5% -> 25% -> 50% -> 100%
# With automated health, latency, 5xx error monitoring, interrupt traps,
# and automatic emergency rollback.
# ==============================================================================

set -euo pipefail

# Configuration
SERVICE="rideos-backend-api"
REGION="us-central1"
PROJECT="rideos-ai"
PROD_REV="rideos-backend-api-00004-xcj"
CANDIDATE_REV="rideos-backend-api-00009-4gt"
PROD_URL="https://rideos-backend-api-121485873641.us-central1.run.app"
CANDIDATE_TAG_URL="https://candidate---rideos-backend-api-aeoxwaaccq-uc.a.run.app"

# Latency and sample thresholds
MAX_ALLOWED_LATENCY_MS=3000
SAMPLE_REQUEST_COUNT=5
OBSERVATION_WINDOW_SECS=30

export CLOUDSDK_METRICS_ENVIRONMENT="datacloud.antigravity"

# Execution state tracking for interrupt safety
CURRENT_STAGE_PCT=0
TRAFFIC_SHIFT_ACTIVE=0

log() {
  echo -e "\033[1;34m[$(date -u +"%Y-%m-%dT%H:%M:%SZ")][ROLLOUT]\033[0m $*"
}

log_success() {
  echo -e "\033[1;32m[$(date -u +"%Y-%m-%dT%H:%M:%SZ")][SUCCESS]\033[0m $*"
}

log_warn() {
  echo -e "\033[1;33m[$(date -u +"%Y-%m-%dT%H:%M:%SZ")][WARNING]\033[0m $*"
}

log_error() {
  echo -e "\033[1;31m[$(date -u +"%Y-%m-%dT%H:%M:%SZ")][ERROR]\033[0m $*"
}

emergency_rollback() {
  local reason="${1:-Unknown failure}"
  log_error "CRITICAL FAILURE DETECTED: $reason"
  log_warn "TRIGGERING AUTOMATIC EMERGENCY ROLLBACK TO $PROD_REV (100%)..."
  
  gcloud run services update-traffic "$SERVICE" \
    --to-revisions="$PROD_REV=100" \
    --region="$REGION" \
    --project="$PROJECT" \
    --quiet
  
  TRAFFIC_SHIFT_ACTIVE=0
  log_success "Rollback completed. 100% traffic safely restored to $PROD_REV."
  exit 1
}

# Trap for unexpected termination (SIGINT / SIGTERM) during canary execution
handle_interrupt() {
  log_warn "Process interrupted by signal!"
  if [[ "$TRAFFIC_SHIFT_ACTIVE" -eq 1 ]]; then
    emergency_rollback "Execution interrupted while canary traffic was active."
  else
    log "No active canary traffic shift in progress. Exiting cleanly."
    exit 130
  fi
}

trap handle_interrupt SIGINT SIGTERM

# 1. Current Status & Pre-flight Health Verification
check_status() {
  log "Inspecting Cloud Run service traffic configuration..."
  gcloud run services describe "$SERVICE" \
    --region="$REGION" \
    --project="$PROJECT" \
    --format="yaml(status.traffic)"

  log "Verifying Candidate Revision ($CANDIDATE_REV) health..."
  
  # A. Readiness Probe (Verifies MongoDB connectivity)
  local cand_readiness
  cand_readiness=$(curl -sS -m 10 "$CANDIDATE_TAG_URL/api/v1/health/readiness" || echo "FAIL")
  if [[ "$cand_readiness" == *"\"ready\":true"* && "$cand_readiness" == *"\"status\":\"healthy\""* ]]; then
    log_success "Candidate readiness probe: HEALTHY (MongoDB status: healthy)"
  else
    log_error "Candidate readiness probe FAILED: $cand_readiness"
    return 1
  fi

  # B. Liveness Probe
  local cand_liveness
  cand_liveness=$(curl -sS -m 5 "$CANDIDATE_TAG_URL/api/v1/health/liveness" || echo "FAIL")
  if [[ "$cand_liveness" == *"\"status\":\"LIVE\""* ]]; then
    log_success "Candidate liveness probe: LIVE"
  else
    log_error "Candidate liveness probe FAILED: $cand_liveness"
    return 1
  fi

  # C. System Health Endpoint
  local cand_health
  cand_health=$(curl -sS -m 5 "$CANDIDATE_TAG_URL/api/v1/health" || echo "FAIL")
  if [[ "$cand_health" == *"\"status\":\"UP\""* && "$cand_health" == *"\"database\":\"healthy\""* ]]; then
    log_success "Candidate system health: UP (Database component: healthy)"
  else
    log_error "Candidate system health FAILED: $cand_health"
    return 1
  fi
}

# 2. Probe Validation & Latency Sampling
verify_traffic_health() {
  local target_url="$1"
  local stage_name="$2"
  log "Running health & latency verification for $stage_name ($SAMPLE_REQUEST_COUNT samples)..."

  local failure_count=0
  local total_time_ms=0

  for i in $(seq 1 "$SAMPLE_REQUEST_COUNT"); do
    local start_ns
    start_ns=$(date +%s%N)
    
    local http_code
    http_code=$(curl -sS -o /dev/null -w "%{http_code}" -m 5 "$target_url/api/v1/health/liveness" || echo "000")
    
    local end_ns
    end_ns=$(date +%s%N)
    local elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))

    if [[ "$http_code" -ge 200 && "$http_code" -lt 400 ]]; then
      log "Sample $i: HTTP $http_code (${elapsed_ms}ms)"
      total_time_ms=$(( total_time_ms + elapsed_ms ))
    else
      log_warn "Sample $i FAILED with HTTP $http_code (${elapsed_ms}ms)"
      failure_count=$(( failure_count + 1 ))
    fi
  done

  if [[ "$failure_count" -gt 0 ]]; then
    emergency_rollback "$failure_count out of $SAMPLE_REQUEST_COUNT probe requests failed on $stage_name."
  fi

  local avg_latency=$(( total_time_ms / SAMPLE_REQUEST_COUNT ))
  log_success "$stage_name probe check passed: Avg Latency = ${avg_latency}ms (Threshold: ${MAX_ALLOWED_LATENCY_MS}ms)"

  if [[ "$avg_latency" -gt "$MAX_ALLOWED_LATENCY_MS" ]]; then
    emergency_rollback "Average latency ${avg_latency}ms exceeded maximum allowed threshold ${MAX_ALLOWED_LATENCY_MS}ms."
  fi
}

# 3. Log Audit for 5xx and SSL/Database Errors
audit_application_logs() {
  local stage_name="$1"
  log "Auditing Cloud Logging for $CANDIDATE_REV errors in the last 2 minutes..."
  
  local error_logs
  error_logs=$(gcloud logging read \
    "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"$SERVICE\" AND resource.labels.revision_name=\"$CANDIDATE_REV\" AND severity>=ERROR AND timestamp >= \"$(date -u -v-2M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d '2 minutes ago' +"%Y-%m-%dT%H:%M:%SZ")\"" \
    --project="$PROJECT" \
    --limit=10 \
    --format="value(textPayload)" 2>/dev/null || true)

  # Check for critical errors (excluding handled 404/400 test cases)
  if echo "$error_logs" | grep -Ei "(MongoServerSelectionError|SSL alert|ECONNREFUSED|ENOTFOUND|crash|fatal)" > /dev/null; then
    emergency_rollback "Critical database/SSL error detected in logs during $stage_name: $(echo "$error_logs" | head -n 3)"
  fi
  
  log_success "Cloud Logging audit passed for $stage_name: No database or SSL errors detected."
}

# 4. Shift Traffic to a Specific Stage (Guarded by confirmation)
apply_stage() {
  local candidate_pct="$1"
  local confirmed="${2:-}"
  local prod_pct=$(( 100 - candidate_pct ))
  local stage_label="${candidate_pct}% Canary (${PROD_REV}=${prod_pct}%, ${CANDIDATE_REV}=${candidate_pct}%)"

  log "=================================================================="
  log "PREPARING TRAFFIC SHIFT TO: $stage_label"
  log "=================================================================="

  # Explicit confirmation safety gate
  if [[ "$confirmed" != "--confirm" && "${CONFIRM_ROLLOUT:-}" != "yes" ]]; then
    log_warn "Safety Gate: Production traffic change requires explicit confirmation."
    log_warn "To execute, run: $0 stage $candidate_pct --confirm"
    log_warn "Or set environment variable: CONFIRM_ROLLOUT=yes"
    exit 0
  fi

  # Step A: Pre-flight candidate health check
  check_status

  # Step B: Mark traffic shift active (arms interrupt rollback trap)
  CURRENT_STAGE_PCT="$candidate_pct"
  TRAFFIC_SHIFT_ACTIVE=1

  # Step C: Execute Cloud Run traffic update
  log "Applying traffic allocation..."
  if [[ "$candidate_pct" -eq 100 ]]; then
    gcloud run services update-traffic "$SERVICE" \
      --to-revisions="$CANDIDATE_REV=100" \
      --region="$REGION" \
      --project="$PROJECT" \
      --quiet
    TRAFFIC_SHIFT_ACTIVE=0
  else
    gcloud run services update-traffic "$SERVICE" \
      --to-revisions="$PROD_REV=$prod_pct,$CANDIDATE_REV=$candidate_pct" \
      --region="$REGION" \
      --project="$PROJECT" \
      --quiet
  fi
  log_success "Traffic update command succeeded."

  # Step D: Observation window
  log "Entering $OBSERVATION_WINDOW_SECS second observation window..."
  sleep "$OBSERVATION_WINDOW_SECS"

  # Step E: Post-shift health, probe, and latency verification
  verify_traffic_health "$PROD_URL" "$stage_label"

  # Step F: Post-shift Cloud Logging audit
  audit_application_logs "$stage_label"

  log_success "Stage $candidate_pct% canary rollout VERIFIED AND STABLE."
}

# Entrypoint dispatch
case "${1:-status}" in
  status|--status)
    check_status
    ;;
  verify-candidate|--verify-candidate)
    check_status
    verify_traffic_health "$CANDIDATE_TAG_URL" "Candidate Tag Pre-Verification"
    audit_application_logs "Candidate Tag Pre-Verification"
    ;;
  stage)
    STAGE_NUM="${2:-}"
    CONFIRM_FLAG="${3:-}"
    if [[ "$STAGE_NUM" =~ ^(1|5|25|50|100)$ ]]; then
      apply_stage "$STAGE_NUM" "$CONFIRM_FLAG"
    else
      log_error "Invalid stage '$STAGE_NUM'. Valid stages: 1, 5, 25, 50, 100"
      exit 1
    fi
    ;;
  rollback|--rollback)
    emergency_rollback "Manual operator rollback requested."
    ;;
  *)
    echo "Usage: $0 {status|verify-candidate|stage <1|5|25|50|100> [--confirm]|rollback}"
    exit 1
    ;;
esac
