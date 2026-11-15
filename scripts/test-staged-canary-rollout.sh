#!/usr/bin/env bash
# ==============================================================================
# RideOS AI — Comprehensive Automated Safety & Rollback Test Suite
# ==============================================================================
# Tests staged-canary-rollout.sh using stateful mocked gcloud/curl/sleep:
# zero live gcloud mutations, zero production traffic shifting, portable timing,
# full Cloud Run service resource JSON, and verified emergency rollbacks.
# ==============================================================================

set -euo pipefail

SCRIPT_UNDER_TEST="./scripts/staged-canary-rollout.sh"
PASS_COUNT=0
FAIL_COUNT=0

# Create isolated test sandbox
TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/rideos_rollout_test_XXXXXX")
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

MOCK_BIN="$TEST_TMP_DIR/bin"
mkdir -p "$MOCK_BIN"

assert_eq() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  [PASS] $test_name"
    PASS_COUNT=$(( PASS_COUNT + 1 ))
  else
    echo "  [FAIL] $test_name (Expected: '$expected', Got: '$actual')"
    FAIL_COUNT=$(( FAIL_COUNT + 1 ))
  fi
}

assert_contains() {
  local test_name="$1"
  local haystack="$2"
  local needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  [PASS] $test_name"
    PASS_COUNT=$(( PASS_COUNT + 1 ))
  else
    echo "  [FAIL] $test_name (Substring '$needle' not found in output)"
    FAIL_COUNT=$(( FAIL_COUNT + 1 ))
  fi
}

echo "=================================================================="
echo "🚀 RideOS AI — Canary Rollout Controller Safety & Rollback Tests"
echo "=================================================================="

# ------------------------------------------------------------------------------
# Test 1: Bash syntax validation
# ------------------------------------------------------------------------------
echo "Test 1: Bash syntax validation"
if bash -n "$SCRIPT_UNDER_TEST"; then
  echo "  [PASS] bash -n exited cleanly (zero syntax errors)"
  PASS_COUNT=$(( PASS_COUNT + 1 ))
else
  echo "  [FAIL] bash -n syntax error"
  FAIL_COUNT=$(( FAIL_COUNT + 1 ))
fi

# ------------------------------------------------------------------------------
# Test 2: Usage / Help output on invalid command
# ------------------------------------------------------------------------------
echo "Test 2: Usage / Help output on invalid command"
set +e
output=$("$SCRIPT_UNDER_TEST" invalid-cmd 2>&1)
exit_code=$?
set -e
assert_eq "Exits with code 1 on invalid argument" "1" "$exit_code"
assert_contains "Usage string present in output" "$output" "Usage:"

# ------------------------------------------------------------------------------
# Test 3: Invalid stage number validation
# ------------------------------------------------------------------------------
echo "Test 3: Invalid stage number rejection"
set +e
output=$("$SCRIPT_UNDER_TEST" stage 99 2>&1)
exit_code=$?
set -e
assert_eq "Exits with code 1 on stage 99" "1" "$exit_code"
assert_contains "Reports invalid stage error" "$output" "Invalid stage '99'"

# ------------------------------------------------------------------------------
# Test 4: Safety gate blocks execution without confirmation
# ------------------------------------------------------------------------------
echo "Test 4: Safety gate blocks execution without --confirm"
set +e
output=$("$SCRIPT_UNDER_TEST" stage 1 2>&1)
exit_code=$?
set -e
assert_eq "Exits safely with code 0 on blocked execution" "0" "$exit_code"
assert_contains "Safety Gate warning displayed" "$output" "Safety Gate: Production traffic change requires explicit confirmation"

# ------------------------------------------------------------------------------
# Setup Stateful Mock Harness with Full Cloud Run Resource JSON
# ------------------------------------------------------------------------------

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
echo "$*" >> "$MOCK_LOG_DIR/gcloud_calls.log"

STATE_FILE="$MOCK_LOG_DIR/simulated_traffic.json"
if [[ ! -f "$STATE_FILE" ]]; then
  cat <<'JSON' > "$STATE_FILE"
{
  "apiVersion": "serving.knative.dev/v1",
  "kind": "Service",
  "metadata": {
    "name": "rideos-backend-api",
    "namespace": "rideos-ai"
  },
  "status": {
    "traffic": [
      { "percent": 100, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 0, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
fi

case "$*" in
  *"run services update-traffic"*)
    echo "$*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"

    # Simulate rollback failure
    if [[ -f "$MOCK_LOG_DIR/fail_rollback_cmd" && "$*" == *"--to-revisions=rideos-backend-api-00004-xcj=100"* ]]; then
      echo "ERROR: simulated rollback command network failure" >&2
      exit 1
    fi

    # Simulate update failure BEFORE mutation
    if [[ -f "$MOCK_LOG_DIR/fail_update_traffic_before" ]]; then
      rm -f "$MOCK_LOG_DIR/fail_update_traffic_before"
      echo "ERROR: simulated update-traffic failure before mutation" >&2
      exit 1
    fi

    # Parse allocations from args: e.g. --to-revisions=prod=95,cand=5 or cand=100
    rev_arg=$(echo "$*" | grep -o '\-\-to-revisions=[^ ]*' | cut -d'=' -f2-)
    node -e '
      const fs = require("fs");
      const revArg = process.argv[1];
      const statePath = process.argv[2];

      let prodPct = 0;
      let candPct = 0;

      const pairs = revArg.split(",");
      for (const p of pairs) {
        const [rev, pctStr] = p.split("=");
        const pct = parseInt(pctStr, 10);
        if (rev === "rideos-backend-api-00004-xcj") prodPct = pct;
        if (rev === "rideos-backend-api-00009-4gt") candPct = pct;
      }

      const resource = {
        apiVersion: "serving.knative.dev/v1",
        kind: "Service",
        metadata: { name: "rideos-backend-api", namespace: "rideos-ai" },
        status: {
          traffic: [
            { percent: prodPct, revisionName: "rideos-backend-api-00004-xcj" },
            { percent: candPct, revisionName: "rideos-backend-api-00009-4gt", tag: "candidate" }
          ]
        }
      };
      fs.writeFileSync(statePath, JSON.stringify(resource, null, 2));
    ' "$rev_arg" "$STATE_FILE"

    # If this is a rollback update to 100% prod, clear stage-level injection flags so rollback verification sees the clean state
    if [[ "$rev_arg" == *"$PROD_REV=100"* ]]; then
      rm -f "$MOCK_LOG_DIR/simulate_mismatched_traffic" "$MOCK_LOG_DIR/simulate_malformed_traffic"
    fi

    # Simulate update failure AFTER mutation
    if [[ -f "$MOCK_LOG_DIR/fail_update_traffic_after" ]]; then
      rm -f "$MOCK_LOG_DIR/fail_update_traffic_after"
      echo "ERROR: simulated update-traffic failure after partial mutation" >&2
      exit 1
    fi

    exit 0
    ;;

  *"run services describe"*)
    if [[ "$*" == *"--format=json"* || "$*" == *'--format="json"'* || "$*" == *'--format="json(status.traffic)"'* ]]; then
      if [[ -f "$MOCK_LOG_DIR/simulate_mismatched_traffic" ]]; then
        cat <<'JSON'
{
  "apiVersion": "serving.knative.dev/v1",
  "kind": "Service",
  "status": {
    "traffic": [
      { "percent": 80, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 10, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
      elif [[ -f "$MOCK_LOG_DIR/simulate_rollback_verification_mismatch" ]]; then
        cat <<'JSON'
{
  "apiVersion": "serving.knative.dev/v1",
  "kind": "Service",
  "status": {
    "traffic": [
      { "percent": 75, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 25, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
      elif [[ -f "$MOCK_LOG_DIR/simulate_malformed_traffic" ]]; then
        echo 'CORRUPT_NON_JSON_RESOURCE_DATA'
      else
        cat "$STATE_FILE"
      fi
    else
      echo "- percent: 100"
      echo "  revisionName: rideos-backend-api-00004-xcj"
      echo "- percent: 0"
      echo "  revisionName: rideos-backend-api-00009-4gt"
      echo "  tag: candidate"
    fi
    exit 0
    ;;

  *"logging read"*)
    if [[ -f "$MOCK_LOG_DIR/inject_log_error" ]]; then
      echo "MongoServerSelectionError: connection timed out to cluster"
    else
      echo ""
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

# Stateful Mock sleep
cat <<'EOF' > "$MOCK_BIN/sleep"
#!/usr/bin/env bash
echo "SLEEP:$1" >> "$MOCK_LOG_DIR/sleep.log"
if [[ -f "$MOCK_LOG_DIR/simulate_sigint_in_sleep" ]]; then
  rm -f "$MOCK_LOG_DIR/simulate_sigint_in_sleep"
  kill -INT "$PPID"
fi
if [[ -f "$MOCK_LOG_DIR/simulate_sigterm_in_sleep" ]]; then
  rm -f "$MOCK_LOG_DIR/simulate_sigterm_in_sleep"
  kill -TERM "$PPID"
fi
exit 0
EOF
chmod +x "$MOCK_BIN/sleep"

# Stateful Mock curl
cat <<'EOF' > "$MOCK_BIN/curl"
#!/usr/bin/env bash
out_file=""
format=""
url=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      out_file="$2"
      shift 2
      ;;
    -w)
      format="$2"
      shift 2
      ;;
    http*)
      url="$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# 1. Readiness Probe
if [[ "$url" == *"health/readiness"* ]]; then
  if [[ -f "$MOCK_LOG_DIR/fail_readiness_ready_false" ]]; then
    # Injects ready: false with generic status: healthy to test strict field gating
    [[ -n "$out_file" ]] && echo '{"status":"healthy","ready":false,"dependencies":{"mongodb":{"status":"healthy"}}}' > "$out_file"
    echo -e "\n200:0.040"
  elif [[ -f "$MOCK_LOG_DIR/fail_readiness" ]]; then
    [[ -n "$out_file" ]] && echo '{"status":"unhealthy","ready":false,"dependencies":{"mongodb":{"status":"unhealthy"}}}' > "$out_file"
    echo -e "\n503:0.040"
  else
    [[ -n "$out_file" ]] && echo '{"status":"healthy","ready":true,"dependencies":{"mongodb":{"status":"healthy"}}}' > "$out_file"
    echo -e "\n200:0.035"
  fi
  exit 0
fi

# 2. Liveness Probe
if [[ "$url" == *"health/liveness"* ]]; then
  if [[ "$url" != *"candidate---"* && -f "$MOCK_LOG_DIR/fail_5xx" ]]; then
    [[ -n "$out_file" ]] && echo 'Internal Server Error' > "$out_file"
    echo -e "\n500:0.050"
  elif [[ "$url" != *"candidate---"* && -f "$MOCK_LOG_DIR/fail_high_latency" ]]; then
    [[ -n "$out_file" ]] && echo '{"status":"LIVE"}' > "$out_file"
    echo -e "\n200:4.200"
  else
    [[ -n "$out_file" ]] && echo '{"status":"LIVE"}' > "$out_file"
    echo -e "\n200:0.025"
  fi
  exit 0
fi

# 3. Overall System Health
if [[ "$url" == *"health" ]]; then
  if [[ -f "$MOCK_LOG_DIR/fail_db_health" ]]; then
    [[ -n "$out_file" ]] && echo '{"status":"DOWN","components":{"database":"disconnected"}}' > "$out_file"
    echo -e "\n503:0.045"
  else
    [[ -n "$out_file" ]] && echo '{"status":"UP","components":{"database":"healthy"}}' > "$out_file"
    echo -e "\n200:0.030"
  fi
  exit 0
fi

exit 0
EOF
chmod +x "$MOCK_BIN/curl"

# ------------------------------------------------------------------------------
# Test 5: Genuine --dry-run mode causes ZERO production mutations
# ------------------------------------------------------------------------------
echo "Test 5: Dry-run mode displays planned allocation with zero gcloud mutations"
MOCK_LOG_DIR="$TEST_TMP_DIR/run_dry_run"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 5 --dry-run 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Dry-run exits with code 0" "0" "$exit_code"
assert_eq "Dry-run makes exactly 0 update-traffic mutations" "0" "$mutation_count"
assert_contains "Dry-run displays planned allocation" "$output" "Planned traffic allocation"
assert_contains "Dry-run confirmation message present" "$output" "[DRY-RUN] Simulated stage 5% validation PASSED"

# ------------------------------------------------------------------------------
# Test 6: Verify traffic allocation command arguments for all stages
# ------------------------------------------------------------------------------
echo "Test 6: Correct traffic allocations for stages 1, 5, 25, 50, 100"
for stage in 1 5 25 50 100; do
  MOCK_LOG_DIR="$TEST_TMP_DIR/stage_$stage"
  mkdir -p "$MOCK_LOG_DIR"
  touch "$MOCK_LOG_DIR/gcloud_mutations.log"

  set +e
  GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
    "$SCRIPT_UNDER_TEST" stage "$stage" --confirm > /dev/null 2>&1
  set -e

  prod_pct=$(( 100 - stage ))
  mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")

  if [[ "$stage" -eq 100 ]]; then
    assert_contains "Stage $stage sets candidate=100" "$mutations" "--to-revisions=rideos-backend-api-00009-4gt=100"
  else
    assert_contains "Stage $stage sets prod=$prod_pct and cand=$stage" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=$prod_pct,rideos-backend-api-00009-4gt=$stage"
  fi
done

# ------------------------------------------------------------------------------
# Test 7: Pre-flight failed candidate readiness blocks traffic shift
# ------------------------------------------------------------------------------
echo "Test 7: Pre-flight failed readiness prevents traffic update"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_preflight"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_readiness"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with failure code 1 on failed pre-flight readiness" "1" "$exit_code"
assert_eq "Zero traffic mutations performed on failed pre-flight" "0" "$mutation_count"
assert_contains "Readiness probe failure logged" "$output" "Candidate readiness probe FAILED"

# ------------------------------------------------------------------------------
# Test 8: HTTP 5xx during post-shift verification triggers emergency rollback
# ------------------------------------------------------------------------------
echo "Test 8: HTTP 5xx probe failure triggers emergency rollback and verifies 100% prod"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_5xx_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_5xx"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 after verified emergency rollback" "1" "$exit_code"
assert_contains "Rollback command executed to 100% prod" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"
assert_contains "Emergency rollback logged" "$output" "TRIGGERING AUTOMATIC EMERGENCY ROLLBACK"
assert_contains "Rollback verified successfully" "$output" "Rollback verified successfully"

# ------------------------------------------------------------------------------
# Test 9: Excessive latency triggers emergency rollback
# ------------------------------------------------------------------------------
echo "Test 9: Excessive latency (>3000ms) triggers emergency rollback"
MOCK_LOG_DIR="$TEST_TMP_DIR/latency_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_high_latency"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 25 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 on excessive latency" "1" "$exit_code"
assert_contains "Rollback command executed to 100% prod" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"
assert_contains "Latency threshold failure logged" "$output" "exceeded maximum allowed threshold"

# ------------------------------------------------------------------------------
# Test 10: Critical Cloud Logging error triggers emergency rollback
# ------------------------------------------------------------------------------
echo "Test 10: Critical log error (MongoServerSelectionError) triggers emergency rollback"
MOCK_LOG_DIR="$TEST_TMP_DIR/log_error_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/inject_log_error"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 on database error log" "1" "$exit_code"
assert_contains "Rollback command executed to 100% prod" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"
assert_contains "Database error detection logged" "$output" "Critical database/SSL error detected in logs"

# ------------------------------------------------------------------------------
# Test 11: SIGINT interrupt during observation window triggers safe rollback
# ------------------------------------------------------------------------------
echo "Test 11: SIGINT interrupt during observation window triggers safe rollback"
MOCK_LOG_DIR="$TEST_TMP_DIR/sigint_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/simulate_sigint_in_sleep"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 50 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_contains "Process interrupt logged" "$output" "Process interrupted by signal!"
assert_contains "Rollback triggered on SIGINT" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"

# ------------------------------------------------------------------------------
# Test 12: Independent SIGTERM interrupt during observation window triggers safe rollback
# ------------------------------------------------------------------------------
echo "Test 12: Independent SIGTERM interrupt during observation window triggers safe rollback"
MOCK_LOG_DIR="$TEST_TMP_DIR/sigterm_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/simulate_sigterm_in_sleep"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 25 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_contains "Process interrupt logged on SIGTERM" "$output" "Process interrupted by signal!"
assert_contains "Rollback triggered on SIGTERM" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"

# ------------------------------------------------------------------------------
# Test 13: Actual traffic mismatch detection triggers rollback and restores 100% prod state
# ------------------------------------------------------------------------------
echo "Test 13: Actual traffic mismatch detection triggers rollback and restores 100% prod state"
MOCK_LOG_DIR="$TEST_TMP_DIR/mismatch_traffic_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/simulate_mismatched_traffic"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 on traffic mismatch" "1" "$exit_code"
assert_contains "Mismatch detection logged" "$output" "Traffic allocation verification failed"
assert_contains "Emergency rollback command executed" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"

# Verify stateful simulated traffic file was restored to prod=100, cand=0
simulated_state=$(cat "$MOCK_LOG_DIR/simulated_traffic.json")
assert_contains "Final simulated state restored to prod=100%" "$simulated_state" '"percent": 100'
assert_contains "Final simulated state restored to cand=0%" "$simulated_state" '"percent": 0'

# ------------------------------------------------------------------------------
# Test 14: Strict JSON readiness validation blocks ready=false despite status=healthy
# ------------------------------------------------------------------------------
echo "Test 14: Strict JSON field validation rejects payload when ready=false despite status=healthy"
MOCK_LOG_DIR="$TEST_TMP_DIR/strict_json_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_readiness_ready_false"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with failure code 1 on ready=false" "1" "$exit_code"
assert_eq "Zero traffic mutations performed on ready=false" "0" "$mutation_count"
assert_contains "Ready false rejection logged" "$output" "ready field is false, expected true"

# ------------------------------------------------------------------------------
# Test 15: Stage 100 retains rollback protection throughout observation window
# ------------------------------------------------------------------------------
echo "Test 15: Stage 100 retains rollback protection throughout observation window"
MOCK_LOG_DIR="$TEST_TMP_DIR/stage_100_interrupt"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/simulate_sigint_in_sleep"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 100 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_contains "Stage 100 executed candidate=100" "$mutations" "--to-revisions=rideos-backend-api-00009-4gt=100"
assert_contains "Stage 100 interrupted during observation rolled back to 100% prod" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"

# ------------------------------------------------------------------------------
# Test 16: Manual rollback command works directly
# ------------------------------------------------------------------------------
echo "Test 16: Manual rollback command restores 100% production revision"
MOCK_LOG_DIR="$TEST_TMP_DIR/manual_rollback"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" rollback 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_contains "Manual rollback updates traffic to 100% prod" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"

# ------------------------------------------------------------------------------
# Test 17: Update-traffic fails before mutation -> triggers recovery & verifies 100%
# ------------------------------------------------------------------------------
echo "Test 17: Update-traffic command failure before mutation triggers safe rollback"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_update_before_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_update_traffic_before"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 after recovery" "1" "$exit_code"
assert_contains "Failure detected on command" "$output" "gcloud update-traffic command failed"
assert_contains "Rollback attempted to 100% prod" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"
assert_contains "Rollback verified" "$output" "Rollback verified successfully"

# ------------------------------------------------------------------------------
# Test 18: Update-traffic fails after partial mutation -> triggers recovery & verifies 100%
# ------------------------------------------------------------------------------
echo "Test 18: Update-traffic command failure after partial mutation triggers safe rollback"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_update_after_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_update_traffic_after"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 25 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 after recovery" "1" "$exit_code"
assert_contains "Failure detected and recovery logged" "$output" "gcloud update-traffic command failed"
assert_contains "Rollback executed to 100% prod" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"
simulated_state=$(cat "$MOCK_LOG_DIR/simulated_traffic.json")
assert_contains "State restored to prod=100%" "$simulated_state" '"percent": 100'

# ------------------------------------------------------------------------------
# Test 19: Rollback command failure -> reports CRITICAL_ROLLBACK_UNVERIFIED
# ------------------------------------------------------------------------------
echo "Test 19: Rollback command failure reports CRITICAL_ROLLBACK_UNVERIFIED (exit code 2)"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_rollback_cmd_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_5xx"
touch "$MOCK_LOG_DIR/fail_rollback_cmd"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

assert_eq "Exits with code 2 on unverified rollback" "2" "$exit_code"
assert_contains "CRITICAL_ROLLBACK_UNVERIFIED reported" "$output" "CRITICAL_ROLLBACK_UNVERIFIED"

# ------------------------------------------------------------------------------
# Test 20: Rollback verification mismatch -> reports CRITICAL_ROLLBACK_UNVERIFIED
# ------------------------------------------------------------------------------
echo "Test 20: Rollback verification mismatch reports CRITICAL_ROLLBACK_UNVERIFIED (exit code 2)"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_rollback_mismatch_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_5xx"
touch "$MOCK_LOG_DIR/simulate_rollback_verification_mismatch"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

assert_eq "Exits with code 2 on verification mismatch" "2" "$exit_code"
assert_contains "CRITICAL_ROLLBACK_UNVERIFIED reported on mismatch" "$output" "CRITICAL_ROLLBACK_UNVERIFIED"

# ------------------------------------------------------------------------------
# Test 21: Malformed Cloud Run traffic JSON payload handled safely
# ------------------------------------------------------------------------------
echo "Test 21: Malformed Cloud Run traffic JSON triggers safe emergency rollback"
MOCK_LOG_DIR="$TEST_TMP_DIR/malformed_json_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/simulate_malformed_traffic"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 after rollback on malformed JSON" "1" "$exit_code"
assert_contains "Parse failure detected" "$output" "Failed to parse traffic JSON"
assert_contains "Rollback command executed" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"

echo ""
echo "=================================================================="
echo "📊 TEST RESULTS: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "=================================================================="

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
