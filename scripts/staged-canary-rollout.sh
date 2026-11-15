#!/usr/bin/env bash
# ==============================================================================
# RideOS AI — Automated Staged Canary Rollout & Rollback Controller
# ==============================================================================
# Controlled traffic progression: 1% -> 5% -> 25% -> 50% -> 100%
# With pre-shift snapshot capture, known-unhealthy destination rejection,
# automated health, latency, 5xx monitoring, interrupt traps,
# actual traffic allocation verification, and verified emergency rollback.
# ==============================================================================

set -euo pipefail

# Configuration
SERVICE="${SERVICE:-rideos-backend-api}"
REGION="${REGION:-us-central1}"
PROJECT="${PROJECT:-rideos-ai}"
BASELINE_FILE="${BASELINE_FILE:-.cloud-run-baseline}"
KNOWN_UNHEALTHY_REVISIONS="${KNOWN_UNHEALTHY_REVISIONS:-rideos-backend-api-00004-xcj}"

# Discover or read verified stable baseline if present
STABLE_PROD_REV="${STABLE_PROD_REV:-}"
if [[ -z "$STABLE_PROD_REV" && -f "$BASELINE_FILE" ]]; then
  STABLE_PROD_REV=$(cat "$BASELINE_FILE" 2>/dev/null | tr -d '[:space:]' || echo "")
fi

PROD_REV="${PROD_REV:-rideos-backend-api-00004-xcj}"
CANDIDATE_REV="${CANDIDATE_REV:-rideos-backend-api-00009-4gt}"
PROD_URL="${PROD_URL:-https://rideos-backend-api-aeoxwaaccq-uc.a.run.app}"
CANDIDATE_TAG_URL="${CANDIDATE_TAG_URL:-https://candidate---rideos-backend-api-aeoxwaaccq-uc.a.run.app}"

# Latency and sample thresholds
MAX_ALLOWED_LATENCY_MS="${MAX_ALLOWED_LATENCY_MS:-3000}"
SAMPLE_REQUEST_COUNT="${SAMPLE_REQUEST_COUNT:-5}"
OBSERVATION_WINDOW_SECS="${OBSERVATION_WINDOW_SECS:-30}"

# Command wrappers (allows full mocking in automated test harness)
GCLOUD_CMD="${GCLOUD_CMD:-gcloud}"
CURL_CMD="${CURL_CMD:-curl}"
SLEEP_CMD="${SLEEP_CMD:-sleep}"

export CLOUDSDK_METRICS_ENVIRONMENT="datacloud.antigravity"

# Execution state tracking for interrupt and rollback safety
CURRENT_STAGE_PCT=0
TRAFFIC_SHIFT_ACTIVE=0
DRY_RUN=0
PRE_SHIFT_SNAPSHOT=""

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

# Portable latency measurement using curl's built-in timing
measure_request() {
  local url="$1"
  local timeout_sec="${2:-5}"
  local tmp_file
  tmp_file=$(mktemp "${TMPDIR:-/tmp}/rideos_probe_XXXXXX")

  local curl_out
  curl_out=$($CURL_CMD -sS -m "$timeout_sec" -w "\n%{http_code}:%{time_total}" "$url" -o "$tmp_file" 2>/dev/null || echo -e "\n000:0.0")

  local body
  body=$(cat "$tmp_file" 2>/dev/null || echo "")
  rm -f "$tmp_file"

  local timing_line
  timing_line=$(echo "$curl_out" | tail -n 1)

  local http_code
  local time_sec
  http_code=$(echo "$timing_line" | cut -d':' -f1)
  time_sec=$(echo "$timing_line" | cut -d':' -f2)

  local elapsed_ms
  elapsed_ms=$(awk -v s="$time_sec" 'BEGIN { printf "%d", (s * 1000) }' 2>/dev/null || echo 0)

  echo "${http_code}|${elapsed_ms}|${body}"
}

# Strict JSON field validator
validate_health_payload() {
  local kind="$1" # readiness | liveness | system
  local http_code="$2"
  local raw_json="$3"

  node -e '
    try {
      const kind = process.argv[1];
      const httpCode = parseInt(process.argv[2], 10);
      const raw = process.argv[3];

      if (httpCode !== 200) {
        console.log(`ERR: HTTP status ${httpCode} is not 200`);
        process.exit(0);
      }

      const data = JSON.parse(raw);
      if (typeof data !== "object" || data === null) {
        console.log("ERR: Payload is not a JSON object");
        process.exit(0);
      }

      if (kind === "readiness") {
        if (data.ready !== true) {
          console.log(`ERR: ready field is ${data.ready}, expected true (generic status cannot bypass ready=false)`);
          process.exit(0);
        }
        const dbStatus = data.dependencies?.mongodb?.status || data.status;
        if (dbStatus !== "healthy") {
          console.log(`ERR: MongoDB status is ${dbStatus}, expected healthy`);
          process.exit(0);
        }
      } else if (kind === "liveness") {
        if (data.status !== "LIVE") {
          console.log(`ERR: Liveness status is ${data.status}, expected LIVE`);
          process.exit(0);
        }
      } else if (kind === "system") {
        if (data.status !== "UP") {
          console.log(`ERR: System status is ${data.status}, expected UP`);
          process.exit(0);
        }
        const compDb = data.components?.database;
        if (compDb !== "healthy") {
          console.log(`ERR: Database component is ${compDb}, expected healthy`);
          process.exit(0);
        }
      }
      console.log("OK");
    } catch (e) {
      console.log("ERR: Invalid JSON syntax: " + e.message);
    }
  ' "$kind" "$http_code" "$raw_json" 2>/dev/null || echo "ERR: Health validation script execution failure"
}

# Capture and validate current live traffic snapshot from Cloud Run
capture_traffic_snapshot() {
  local raw_json
  raw_json=$($GCLOUD_CMD run services describe "$SERVICE" \
    --region="$REGION" \
    --project="$PROJECT" \
    --format="json" 2>/dev/null || echo "")

  if [[ -z "$raw_json" ]]; then
    echo "ERR: Empty response from Cloud Run describe"
    return 0
  fi

  node -e '
    try {
      const raw = process.argv[1];
      const parsed = JSON.parse(raw);
      let traffic = null;
      if (Array.isArray(parsed)) {
        traffic = parsed;
      } else if (parsed && parsed.status && Array.isArray(parsed.status.traffic)) {
        traffic = parsed.status.traffic;
      } else {
        console.log("ERR: status.traffic array not found in Cloud Run JSON");
        process.exit(0);
      }

      if (!traffic || traffic.length === 0) {
        console.log("ERR: status.traffic array is empty");
        process.exit(0);
      }

      let totalPct = 0;
      const entries = [];

      for (const t of traffic) {
        if (!t.revisionName || typeof t.revisionName !== "string" || t.revisionName.trim().length === 0) {
          console.log("ERR: Missing or invalid revisionName in traffic entry");
          process.exit(0);
        }
        const pct = parseInt(t.percent !== undefined ? t.percent : 0, 10);
        if (isNaN(pct) || pct < 0) {
          console.log(`ERR: Invalid percentage ${t.percent} for revision ${t.revisionName}`);
          process.exit(0);
        }
        totalPct += pct;
        if (pct > 0) {
          entries.push(`${t.revisionName.trim()}=${pct}`);
        }
      }

      if (totalPct !== 100) {
        console.log(`ERR: Total traffic allocation is ${totalPct}%, expected exactly 100%`);
        process.exit(0);
      }

      if (entries.length === 0) {
        console.log("ERR: No active non-zero traffic allocations found");
        process.exit(0);
      }

      console.log("OK:" + entries.join(","));
    } catch (e) {
      console.log("ERR: Failed to parse Cloud Run JSON: " + e.message);
    }
  ' "$raw_json" 2>/dev/null || echo "ERR: Snapshot parser execution failed"
}

# Check if a candidate rollback destination routes 100% to a known-unhealthy revision
is_known_unhealthy_100_target() {
  local target_alloc="$1"
  for unh in $(echo "$KNOWN_UNHEALTHY_REVISIONS" | tr ',' ' '); do
    if [[ "$target_alloc" == "${unh}=100" || "$target_alloc" == "${unh}=100%" ]]; then
      return 0
    fi
  done
  return 1
}

# Verify that Cloud Run live JSON matches expected snapshot allocations
verify_snapshot_match() {
  local raw_json="$1"
  local expected_alloc="$2"

  node -e '
    try {
      const raw = process.argv[1];
      const expected = process.argv[2];

      if (!raw || raw.trim().length === 0) {
        console.log("ERR: Empty response from Cloud Run describe");
        process.exit(0);
      }

      const parsed = JSON.parse(raw);
      let traffic = null;
      if (Array.isArray(parsed)) {
        traffic = parsed;
      } else if (parsed && parsed.status && Array.isArray(parsed.status.traffic)) {
        traffic = parsed.status.traffic;
      } else {
        console.log("ERR: status.traffic array not found in Cloud Run JSON");
        process.exit(0);
      }

      const expectedMap = {};
      for (const pair of expected.split(",")) {
        const [rev, pctStr] = pair.split("=");
        const pct = parseInt(pctStr, 10);
        expectedMap[rev.trim()] = pct;
      }

      const actualMap = {};
      let actualTotal = 0;
      for (const t of traffic) {
        const rev = (t.revisionName || "").trim();
        const pct = parseInt(t.percent !== undefined ? t.percent : 0, 10);
        actualMap[rev] = (actualMap[rev] || 0) + pct;
        actualTotal += pct;
      }

      if (actualTotal !== 100) {
        console.log(`ERR: Actual total traffic is ${actualTotal}%, expected 100%`);
        process.exit(0);
      }

      for (const [rev, expPct] of Object.entries(expectedMap)) {
        const actPct = actualMap[rev] || 0;
        if (actPct !== expPct) {
          console.log(`ERR: Mismatch for ${rev}: actual=${actPct}%, expected=${expPct}%`);
          process.exit(0);
        }
      }

      console.log(`OK: verified restoration of ${expected}`);
    } catch (e) {
      console.log("ERR: Failed to verify snapshot match: " + e.message);
    }
  ' "$raw_json" "$expected_alloc" 2>/dev/null || echo "ERR: Snapshot verifier execution failure"
}

# Parser for full Cloud Run service resource or traffic array
parse_traffic_json() {
  local raw_json="$1"
  local prod_rev="$2"
  local cand_rev="$3"
  local exp_prod="$4"
  local exp_cand="$5"

  node -e '
    try {
      const raw = process.argv[1];
      const prodRev = process.argv[2];
      const candRev = process.argv[3];
      const expProd = parseInt(process.argv[4], 10);
      const expCand = parseInt(process.argv[5], 10);

      if (!raw || raw.trim().length === 0) {
        console.log("ERR: Empty response from Cloud Run describe");
        process.exit(0);
      }

      const parsed = JSON.parse(raw);
      let traffic = null;
      if (Array.isArray(parsed)) {
        traffic = parsed;
      } else if (parsed && parsed.status && Array.isArray(parsed.status.traffic)) {
        traffic = parsed.status.traffic;
      } else {
        console.log("ERR: status.traffic array not found in Cloud Run JSON");
        process.exit(0);
      }

      let prodPct = 0;
      let candPct = 0;
      let totalPct = 0;

      for (const t of traffic) {
        const pct = parseInt(t.percent || 0, 10);
        totalPct += pct;
        if (t.revisionName === prodRev) {
          prodPct += pct;
        }
        if (t.revisionName === candRev) {
          candPct += pct;
        }
      }

      if (totalPct !== 100) {
        console.log(`ERR: Total traffic is ${totalPct}%, expected exactly 100%`);
        process.exit(0);
      }
      if (prodPct !== expProd) {
        console.log(`ERR: Production revision (${prodRev}) percentage is ${prodPct}%, expected ${expProd}%`);
        process.exit(0);
      }
      if (candPct !== expCand) {
        console.log(`ERR: Candidate revision (${candRev}) percentage is ${candPct}%, expected ${expCand}%`);
        process.exit(0);
      }

      console.log(`OK: prod=${prodPct}, cand=${candPct}, total=${totalPct}`);
    } catch (e) {
      console.log("ERR: Failed to parse traffic JSON: " + e.message);
    }
  ' "$raw_json" "$prod_rev" "$cand_rev" "$exp_prod" "$exp_cand" 2>/dev/null || echo "ERR: Parser execution failed"
}

emergency_rollback() {
  local reason="${1:-Unknown failure}"
  log_error "CRITICAL FAILURE DETECTED: $reason"

  # Reject automatic rollback if no pre-shift snapshot is available
  if [[ -z "${PRE_SHIFT_SNAPSHOT:-}" ]]; then
    # Try capturing snapshot if not yet set
    local snap_res
    snap_res=$(capture_traffic_snapshot)
    if [[ "$snap_res" == OK:* ]]; then
      PRE_SHIFT_SNAPSHOT="${snap_res#OK:}"
    else
      log_error "CRITICAL_ROLLBACK_BLOCKED: No valid pre-shift traffic snapshot available for safe restoration."
      exit 2
    fi
  fi

  # Reject automatic rollback to known-unhealthy revision at 100%
  if is_known_unhealthy_100_target "$PRE_SHIFT_SNAPSHOT"; then
    log_error "CRITICAL_ROLLBACK_BLOCKED: Pre-shift snapshot ($PRE_SHIFT_SNAPSHOT) would route 100% traffic to known-unhealthy revision ($KNOWN_UNHEALTHY_REVISIONS). Automatic 100% routing to known-unhealthy revisions is strictly forbidden."
    exit 2
  fi

  log_warn "TRIGGERING AUTOMATIC RESTORATION TO PRE-SHIFT SNAPSHOT: $PRE_SHIFT_SNAPSHOT..."

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY-RUN] Simulated rollback: Would restore $PRE_SHIFT_SNAPSHOT on $SERVICE (zero mutations)."
    TRAFFIC_SHIFT_ACTIVE=0
    exit 1
  fi

  # Attempt rollback command with explicit failure check
  local rollback_cmd_failed=0
  if ! $GCLOUD_CMD run services update-traffic "$SERVICE" \
    --to-revisions="$PRE_SHIFT_SNAPSHOT" \
    --region="$REGION" \
    --project="$PROJECT" \
    --quiet; then
    rollback_cmd_failed=1
    log_error "CRITICAL: gcloud rollback update-traffic command failed!"
  fi

  # Retrieve actual Cloud Run traffic to verify restoration against PRE_SHIFT_SNAPSHOT
  local raw_verify_json
  raw_verify_json=$($GCLOUD_CMD run services describe "$SERVICE" \
    --region="$REGION" \
    --project="$PROJECT" \
    --format="json" 2>/dev/null || echo "")

  local verify_res
  verify_res=$(verify_snapshot_match "$raw_verify_json" "$PRE_SHIFT_SNAPSHOT")

  if [[ "$rollback_cmd_failed" -eq 0 && "$verify_res" == OK:* ]]; then
    TRAFFIC_SHIFT_ACTIVE=0
    log_success "Rollback verified successfully: Pre-shift allocation safely restored ($PRE_SHIFT_SNAPSHOT)."
    log_warn "NOTE: Traffic allocation restored to pre-shift state. This recovers the previous traffic distribution but does not imply underlying application health recovery on degraded revisions."
    exit 1
  else
    log_error "CRITICAL_ROLLBACK_UNVERIFIED: Could not confirm traffic restoration to $PRE_SHIFT_SNAPSHOT! Details: $verify_res"
    exit 2
  fi
}

# Trap for unexpected termination (SIGINT / SIGTERM) during canary execution
handle_interrupt() {
  log_warn "Process interrupted by signal!"
  if [[ "$TRAFFIC_SHIFT_ACTIVE" -eq 1 ]]; then
    emergency_rollback "Execution interrupted while canary traffic shift was active."
  else
    log "No active canary traffic shift in progress. Exiting cleanly."
    exit 130
  fi
}

trap handle_interrupt SIGINT SIGTERM

# 1. Current Status & Pre-flight Health Verification
check_status() {
  log "Inspecting Cloud Run service traffic configuration..."
  $GCLOUD_CMD run services describe "$SERVICE" \
    --region="$REGION" \
    --project="$PROJECT" \
    --format="yaml(status.traffic)"

  log "Verifying Candidate Revision ($CANDIDATE_REV) health..."

  # A. Readiness Probe (Verifies MongoDB connectivity, with cold-start allowance)
  local res_readiness
  res_readiness=$(measure_request "$CANDIDATE_TAG_URL/api/v1/health/readiness" 30)
  local ready_code
  local ready_body
  ready_code=$(echo "$res_readiness" | cut -d'|' -f1)
  ready_body=$(echo "$res_readiness" | cut -d'|' -f3-)

  # If cold start timed out or returned non-200, retry once with fresh 30s window
  if [[ "$ready_code" != "200" ]]; then
    log_warn "Candidate initial probe returned $ready_code (possible Cloud Run cold-start). Retrying in 3s..."
    $SLEEP_CMD 3
    res_readiness=$(measure_request "$CANDIDATE_TAG_URL/api/v1/health/readiness" 30)
    ready_code=$(echo "$res_readiness" | cut -d'|' -f1)
    ready_body=$(echo "$res_readiness" | cut -d'|' -f3-)
  fi

  local val_ready
  val_ready=$(validate_health_payload "readiness" "$ready_code" "$ready_body")
  if [[ "$val_ready" == "OK" ]]; then
    log_success "Candidate readiness probe: HEALTHY (MongoDB status: healthy, ready: true)"
  else
    log_error "Candidate readiness probe FAILED: $val_ready"
    return 1
  fi

  # B. Liveness Probe
  local res_liveness
  res_liveness=$(measure_request "$CANDIDATE_TAG_URL/api/v1/health/liveness" 5)
  local live_code
  local live_body
  live_code=$(echo "$res_liveness" | cut -d'|' -f1)
  live_body=$(echo "$res_liveness" | cut -d'|' -f3-)

  local val_live
  val_live=$(validate_health_payload "liveness" "$live_code" "$live_body")
  if [[ "$val_live" == "OK" ]]; then
    log_success "Candidate liveness probe: LIVE"
  else
    log_error "Candidate liveness probe FAILED: $val_live"
    return 1
  fi

  # C. System Health Endpoint
  local res_health
  res_health=$(measure_request "$CANDIDATE_TAG_URL/api/v1/health" 5)
  local health_code
  local health_body
  health_code=$(echo "$res_health" | cut -d'|' -f1)
  health_body=$(echo "$res_health" | cut -d'|' -f3-)

  local val_health
  val_health=$(validate_health_payload "system" "$health_code" "$health_body")
  if [[ "$val_health" == "OK" ]]; then
    log_success "Candidate system health: UP (Database component: healthy)"
  else
    log_error "Candidate system health FAILED: $val_health"
    return 1
  fi
}

# 2. Actual Traffic Allocation Verification
verify_actual_traffic_allocation() {
  local expected_prod="$1"
  local expected_cand="$2"
  log "Verifying actual Cloud Run traffic distribution (machine-readable JSON)..."

  local raw_traffic_json
  raw_traffic_json=$($GCLOUD_CMD run services describe "$SERVICE" \
    --region="$REGION" \
    --project="$PROJECT" \
    --format="json" 2>/dev/null || echo "")

  local parse_result
  parse_result=$(parse_traffic_json "$raw_traffic_json" "$PROD_REV" "$CANDIDATE_REV" "$expected_prod" "$expected_cand")

  if [[ "$parse_result" != OK:* ]]; then
    emergency_rollback "Traffic allocation verification failed: $parse_result"
  fi

  log_success "Traffic allocation verified: $parse_result"
}

# 3. Probe Validation & Latency Sampling across Endpoints
verify_traffic_health() {
  local target_url="$1"
  local stage_name="$2"
  log "Running health, readiness & latency verification for $stage_name ($SAMPLE_REQUEST_COUNT samples)..."

  local failure_count=0
  local total_time_ms=0

  for i in $(seq 1 "$SAMPLE_REQUEST_COUNT"); do
    local probe_res
    probe_res=$(measure_request "$target_url/api/v1/health/liveness" 10)
    local http_code
    local elapsed_ms
    local body
    http_code=$(echo "$probe_res" | cut -d'|' -f1)
    elapsed_ms=$(echo "$probe_res" | cut -d'|' -f2)
    body=$(echo "$probe_res" | cut -d'|' -f3-)

    local val_sample
    val_sample=$(validate_health_payload "liveness" "$http_code" "$body")
    if [[ "$val_sample" == "OK" ]]; then
      log "Sample $i: HTTP $http_code (${elapsed_ms}ms)"
      total_time_ms=$(( total_time_ms + elapsed_ms ))
    else
      log_warn "Sample $i FAILED: $val_sample (HTTP $http_code, ${elapsed_ms}ms)"
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

  # Deep Database Readiness and System Health Probes
  if [[ "$CURRENT_STAGE_PCT" -eq 100 || "$target_url" == "$CANDIDATE_TAG_URL" ]]; then
    log "Verifying database readiness on $stage_name endpoint ($target_url)..."
    local deep_res
    deep_res=$(measure_request "$target_url/api/v1/health/readiness" 10)
    local deep_code
    local deep_body
    deep_code=$(echo "$deep_res" | cut -d'|' -f1)
    deep_body=$(echo "$deep_res" | cut -d'|' -f3-)

    local val_deep
    val_deep=$(validate_health_payload "readiness" "$deep_code" "$deep_body")
    if [[ "$val_deep" != "OK" ]]; then
      emergency_rollback "Database readiness verification failed on $stage_name: $val_deep"
    fi
    log_success "Database readiness verified on $stage_name ($target_url)."

    # System Health Probe on Stage URL
    log "Verifying system health on $stage_name endpoint ($target_url)..."
    local sys_res
    sys_res=$(measure_request "$target_url/api/v1/health" 10)
    local sys_code
    local sys_body
    sys_code=$(echo "$sys_res" | cut -d'|' -f1)
    sys_body=$(echo "$sys_res" | cut -d'|' -f3-)

    local val_sys
    val_sys=$(validate_health_payload "system" "$sys_code" "$sys_body")
    if [[ "$val_sys" != "OK" ]]; then
      emergency_rollback "System health verification failed on $stage_name: $val_sys"
    fi
    log_success "System health verified on $stage_name ($target_url)."
  fi

  # Candidate-tag endpoint verification
  if [[ "$target_url" != "$CANDIDATE_TAG_URL" ]]; then
    log "Cross-verifying Candidate-tag direct endpoint ($CANDIDATE_TAG_URL)..."
    local cand_tag_res
    cand_tag_res=$(measure_request "$CANDIDATE_TAG_URL/api/v1/health/readiness" 10)
    local cand_tag_code
    local cand_tag_body
    cand_tag_code=$(echo "$cand_tag_res" | cut -d'|' -f1)
    cand_tag_body=$(echo "$cand_tag_res" | cut -d'|' -f3-)

    local val_cand_tag
    val_cand_tag=$(validate_health_payload "readiness" "$cand_tag_code" "$cand_tag_body")
    if [[ "$val_cand_tag" != "OK" ]]; then
      emergency_rollback "Candidate tag direct endpoint failed readiness during $stage_name: $val_cand_tag"
    fi
    log_success "Candidate tag readiness verified healthy ($CANDIDATE_TAG_URL)."

    # Cross-verify system health on candidate tag direct endpoint
    local cand_tag_sys
    cand_tag_sys=$(measure_request "$CANDIDATE_TAG_URL/api/v1/health" 10)
    local cand_tag_sys_code
    local cand_tag_sys_body
    cand_tag_sys_code=$(echo "$cand_tag_sys" | cut -d'|' -f1)
    cand_tag_sys_body=$(echo "$cand_tag_sys" | cut -d'|' -f3-)

    local val_cand_tag_sys
    val_cand_tag_sys=$(validate_health_payload "system" "$cand_tag_sys_code" "$cand_tag_sys_body")
    if [[ "$val_cand_tag_sys" != "OK" ]]; then
      emergency_rollback "Candidate tag direct endpoint failed system health during $stage_name: $val_cand_tag_sys"
    fi
    log_success "Candidate tag system health verified healthy ($CANDIDATE_TAG_URL)."
  fi
}

# 4. Log Audit for 5xx and SSL/Database Errors
audit_application_logs() {
  local stage_name="$1"
  log "Auditing Cloud Logging for $CANDIDATE_REV errors in the last 2 minutes..."

  local error_logs
  error_logs=$($GCLOUD_CMD logging read \
    "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"$SERVICE\" AND resource.labels.revision_name=\"$CANDIDATE_REV\" AND severity>=ERROR AND timestamp >= \"$(date -u -v-2M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d '2 minutes ago' +"%Y-%m-%dT%H:%M:%SZ")\"" \
    --project="$PROJECT" \
    --limit=10 \
    --format="value(textPayload)" 2>/dev/null || true)

  if echo "$error_logs" | grep -Ei "(MongoServerSelectionError|SSL alert|ECONNREFUSED|ENOTFOUND|crash|fatal)" > /dev/null; then
    emergency_rollback "Critical database/SSL error detected in logs during $stage_name: $(echo "$error_logs" | head -n 3)"
  fi

  log_success "Cloud Logging audit passed for $stage_name: No database or SSL errors detected."
}

# 5. Manual Rollback Action
manual_rollback() {
  local explicit_target="${1:-}"
  log_warn "Manual operator rollback requested."

  local snap_res
  snap_res=$(capture_traffic_snapshot)
  if [[ "$snap_res" != OK:* ]]; then
    log_error "CRITICAL_ROLLBACK_BLOCKED: Unable to inspect current traffic allocation: $snap_res"
    exit 2
  fi
  local current_alloc="${snap_res#OK:}"
  log "Current traffic allocation: $current_alloc"

  # Determine safe rollback destination
  local target_dest=""
  if [[ -n "$explicit_target" ]]; then
    target_dest="$explicit_target"
  elif [[ -n "${STABLE_PROD_REV:-}" && "$STABLE_PROD_REV" != "$CANDIDATE_REV" ]]; then
    target_dest="${STABLE_PROD_REV}=100"
  fi

  if [[ -n "$target_dest" ]] && is_known_unhealthy_100_target "$target_dest"; then
    log_error "CRITICAL_SAFETY_REJECTION: Destination $target_dest is in KNOWN_UNHEALTHY_REVISIONS ($KNOWN_UNHEALTHY_REVISIONS)."
    log_error "CRITICAL_ROLLBACK_BLOCKED: Routing 100% traffic to known-unhealthy revision is strictly forbidden."
    exit 2
  fi

  if [[ -z "$target_dest" ]]; then
    if is_known_unhealthy_100_target "${PROD_REV}=100"; then
      log_warn "Default target ${PROD_REV}=100 is known-unhealthy ($KNOWN_UNHEALTHY_REVISIONS). Restoring pre-shift baseline ($current_alloc) to protect traffic."
      target_dest="$current_alloc"
    else
      target_dest="${PROD_REV}=100"
    fi
  fi

  log_warn "Executing manual rollback to verified safe destination: $target_dest..."
  if ! $GCLOUD_CMD run services update-traffic "$SERVICE" \
    --to-revisions="$target_dest" \
    --region="$REGION" \
    --project="$PROJECT" \
    --quiet; then
    log_error "CRITICAL: gcloud manual rollback command failed!"
    exit 2
  fi

  local raw_verify_json
  raw_verify_json=$($GCLOUD_CMD run services describe "$SERVICE" \
    --region="$REGION" \
    --project="$PROJECT" \
    --format="json" 2>/dev/null || echo "")

  local verify_res
  verify_res=$(verify_snapshot_match "$raw_verify_json" "$target_dest")

  if [[ "$verify_res" == OK:* ]]; then
    log_success "Manual rollback verified: Traffic safely restored to $target_dest."
    exit 0
  else
    log_error "CRITICAL_ROLLBACK_UNVERIFIED: Manual rollback verification failed! Details: $verify_res"
    exit 2
  fi
}

# 6. Shift Traffic to a Specific Stage (Guarded by confirmation and dry-run)
apply_stage() {
  local candidate_pct="$1"
  shift
  local is_confirmed=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --confirm)
        is_confirmed=1
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      *)
        ;;
    esac
    shift
  done

  if [[ "${CONFIRM_ROLLOUT:-}" == "yes" ]]; then
    is_confirmed=1
  fi
  if [[ "${DRY_RUN_ROLLOUT:-}" == "yes" || "${DRY_RUN:-0}" -eq 1 ]]; then
    DRY_RUN=1
  fi

  local prod_pct=$(( 100 - candidate_pct ))
  local stage_label="${candidate_pct}% Canary (${PROD_REV}=${prod_pct}%, ${CANDIDATE_REV}=${candidate_pct}%)"
  local stage_alloc=""
  if [[ "$candidate_pct" -eq 100 ]]; then
    stage_alloc="${CANDIDATE_REV}=100"
  else
    stage_alloc="${PROD_REV}=${prod_pct},${CANDIDATE_REV}=${candidate_pct}"
  fi

  log "=================================================================="
  log "PREPARING TRAFFIC SHIFT TO: $stage_label"
  log "=================================================================="

  # Step 1: Pre-shift snapshot capture and validation BEFORE any mutations
  log "Capturing pre-shift Cloud Run traffic snapshot..."
  local snapshot_res
  snapshot_res=$(capture_traffic_snapshot)

  if [[ "$snapshot_res" != OK:* ]]; then
    log_error "CRITICAL SAFETY GATE: Failed to capture valid pre-shift traffic snapshot: $snapshot_res"
    log_error "Cannot proceed with traffic mutation without verified pre-shift state. Aborting."
    exit 1
  fi

  PRE_SHIFT_SNAPSHOT="${snapshot_res#OK:}"
  log_success "Pre-shift traffic snapshot captured: $PRE_SHIFT_SNAPSHOT"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log_warn "[DRY-RUN] Mode active: Zero production mutations will be performed."
    log "[DRY-RUN] Planned traffic allocation: $SERVICE -> $stage_alloc"
    log "[DRY-RUN] Pre-shift baseline preserved: $PRE_SHIFT_SNAPSHOT"

    # Pre-flight candidate health checks in dry-run mode
    check_status
    log_success "[DRY-RUN] Simulated stage $candidate_pct% validation PASSED. Cloud Run traffic remains intact at $PRE_SHIFT_SNAPSHOT."
    exit 0
  fi

  # Explicit confirmation safety gate for live changes
  if [[ "$is_confirmed" -ne 1 ]]; then
    log_warn "Safety Gate: Production traffic change requires explicit confirmation."
    log_warn "To execute dry-run simulation: $0 stage $candidate_pct --dry-run"
    log_warn "To execute real migration:    $0 stage $candidate_pct --confirm"
    log_warn "Or set environment variable:   CONFIRM_ROLLOUT=yes"
    exit 0
  fi

  # Step A: Pre-flight candidate health check
  check_status

  # Step B: Mark traffic shift active BEFORE attempting update (arms interrupt and rollback traps)
  CURRENT_STAGE_PCT="$candidate_pct"
  TRAFFIC_SHIFT_ACTIVE=1

  # Step C: Execute Cloud Run traffic update with explicit failure handling
  log "Applying traffic allocation ($stage_alloc)..."
  local update_cmd_failed=0
  if ! $GCLOUD_CMD run services update-traffic "$SERVICE" \
    --to-revisions="$stage_alloc" \
    --region="$REGION" \
    --project="$PROJECT" \
    --quiet; then
    update_cmd_failed=1
  fi

  if [[ "$update_cmd_failed" -ne 0 ]]; then
    emergency_rollback "gcloud update-traffic command failed for stage $candidate_pct%. Treating traffic state as ambiguous/potentially mutated; executing recovery."
  fi
  log_success "Traffic update command executed successfully."

  # Step D: Verify post-shift traffic allocation on Cloud Run (machine-readable JSON)
  verify_actual_traffic_allocation "$prod_pct" "$candidate_pct"

  # Step E: Observation window (TRAFFIC_SHIFT_ACTIVE remains 1 throughout!)
  log "Entering $OBSERVATION_WINDOW_SECS second observation window..."
  $SLEEP_CMD "$OBSERVATION_WINDOW_SECS"

  # Step F: Post-shift health, readiness, and latency verification
  verify_traffic_health "$PROD_URL" "$stage_label"

  # Step G: Post-shift Cloud Logging audit
  audit_application_logs "$stage_label"

  # ONLY disarm rollback trap when all verifications and observation window have passed
  TRAFFIC_SHIFT_ACTIVE=0
  log_success "Stage $candidate_pct% canary rollout VERIFIED AND STABLE."

  # Step H: If successfully promoted to 100%, record new stable baseline
  if [[ "$candidate_pct" -eq 100 ]]; then
    log "Recording $CANDIDATE_REV as the new verified stable production baseline..."
    echo "$CANDIDATE_REV" > "$BASELINE_FILE"
    STABLE_PROD_REV="$CANDIDATE_REV"
    log_success "NEW STABLE BASELINE ESTABLISHED: $CANDIDATE_REV (recorded in $BASELINE_FILE)"
  fi
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
    shift 2 || true
    if [[ "$STAGE_NUM" =~ ^(1|5|25|50|100)$ ]]; then
      apply_stage "$STAGE_NUM" "$@"
    else
      log_error "Invalid stage '$STAGE_NUM'. Valid stages: 1, 5, 25, 50, 100"
      exit 1
    fi
    ;;
  rollback|--rollback)
    manual_rollback "${2:-}"
    ;;
  *)
    echo "Usage: $0 {status|verify-candidate|stage <1|5|25|50|100> [--confirm] [--dry-run]|rollback}"
    exit 1
    ;;
esac
