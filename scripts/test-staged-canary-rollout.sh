#!/usr/bin/env bash
# ==============================================================================
# RideOS AI — Comprehensive Automated Safety & Rollback Test Suite
# ==============================================================================
# Tests staged-canary-rollout.sh using stateful mocked gcloud/curl/sleep:
# zero live gcloud mutations, zero production traffic shifting, portable timing,
# full Cloud Run service resource JSON, pre-shift snapshot capture,
# known-unhealthy target rejection, and verified emergency rollbacks.
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

GLOBAL_MUTATIONS_LOG="$TEST_TMP_DIR/all_global_mutations.log"
touch "$GLOBAL_MUTATIONS_LOG"

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
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
fi

case "$*" in
  *"run services update-traffic"*)
    echo "$*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    echo "$*" >> "$GLOBAL_MUTATIONS_LOG"

    # Simulate rollback command failure
    rev_arg=$(echo "$*" | grep -o '\-\-to-revisions=[^ ]*' | cut -d'=' -f2-)
    if [[ -f "$MOCK_LOG_DIR/fail_rollback_cmd" && "$rev_arg" == *"rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"* ]]; then
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
    node -e '
      const fs = require("fs");
      const revArg = process.argv[1];
      const statePath = process.argv[2];

      const pairs = revArg.split(",");
      const traffic = pairs.map(p => {
        const [rev, pctStr] = p.split("=");
        const pct = parseInt(pctStr, 10);
        const obj = { percent: pct, revisionName: rev };
        if (rev === "rideos-backend-api-00009-4gt") {
          obj.tag = "candidate";
        }
        return obj;
      });

      const resource = {
        apiVersion: "serving.knative.dev/v1",
        kind: "Service",
        metadata: { name: "rideos-backend-api", namespace: "rideos-ai" },
        status: {
          traffic: traffic
        }
      };
      fs.writeFileSync(statePath, JSON.stringify(resource, null, 2));
    ' "$rev_arg" "$STATE_FILE"

    # If this is the initial stage update and mismatch on verify is configured:
    if [[ -f "$MOCK_LOG_DIR/simulate_mismatched_traffic_on_verify" && "$rev_arg" != *"rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"* ]]; then
      touch "$MOCK_LOG_DIR/active_mismatched_traffic"
    fi

    # If this is a rollback update to restore pre-shift snapshot:
    if [[ "$rev_arg" == *"rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"* ]]; then
      rm -f "$MOCK_LOG_DIR/active_mismatched_traffic" "$MOCK_LOG_DIR/simulate_mismatched_traffic"
      if [[ -f "$MOCK_LOG_DIR/simulate_rollback_verification_mismatch" ]]; then
        touch "$MOCK_LOG_DIR/active_rollback_verification_mismatch"
      fi
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
    if [[ -f "$MOCK_LOG_DIR/simulate_describe_failure" ]]; then
      echo "ERROR: simulated describe network timeout" >&2
      exit 1
    fi

    if [[ -f "$MOCK_LOG_DIR/simulate_malformed_traffic" ]]; then
      echo 'CORRUPT_NON_JSON_RESOURCE_DATA'
      exit 0
    elif [[ -f "$MOCK_LOG_DIR/active_mismatched_traffic" || -f "$MOCK_LOG_DIR/simulate_mismatched_traffic" ]]; then
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
      exit 0
    elif [[ -f "$MOCK_LOG_DIR/active_rollback_verification_mismatch" ]]; then
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
      exit 0
    fi

    if [[ "$*" == *"--format=json"* || "$*" == *'--format="json"'* || "$*" == *'--format="json(status.traffic)"'* ]]; then
      cat "$STATE_FILE"
    else
      # Default YAML format
      node -e '
        const fs = require("fs");
        const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
        data.status.traffic.forEach(t => {
          console.log(`- percent: ${t.percent}`);
          console.log(`  revisionName: ${t.revisionName}`);
          if (t.tag) console.log(`  tag: ${t.tag}`);
        });
      ' "$STATE_FILE"
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
# Test 5: Genuine --dry-run mode causes ZERO production mutations (Requirement 12)
# ------------------------------------------------------------------------------
echo "Test 5: Dry-run mode displays planned allocation with zero gcloud mutations (Requirement 12)"
MOCK_LOG_DIR="$TEST_TMP_DIR/run_dry_run"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --dry-run 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Dry-run exits with code 0" "0" "$exit_code"
assert_eq "Dry-run makes exactly 0 update-traffic mutations" "0" "$mutation_count"
assert_contains "Dry-run displays planned allocation" "$output" "Planned traffic allocation"
assert_contains "Dry-run preserves pre-shift baseline" "$output" "Pre-shift baseline preserved: rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"
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
  GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
    BASELINE_FILE="$MOCK_LOG_DIR/baseline" \
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
# Test 7: Pre-flight failed candidate readiness blocks traffic shift (Requirement 2)
# ------------------------------------------------------------------------------
echo "Test 7: Pre-flight failed candidate readiness prevents traffic update (Requirement 2)"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_preflight"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_readiness"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with failure code 1 on failed pre-flight readiness" "1" "$exit_code"
assert_eq "Zero traffic mutations performed on failed pre-flight" "0" "$mutation_count"
assert_contains "Readiness probe failure logged" "$output" "Candidate readiness probe FAILED"

# ------------------------------------------------------------------------------
# Test 8: HTTP 5xx probe failure triggers emergency rollback and restores 99/1 (Requirement 3, 6)
# ------------------------------------------------------------------------------
echo "Test 8: HTTP 5xx probe failure triggers emergency rollback and restores 99/1 (Requirement 3, 6)"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_5xx_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_5xx"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 after verified emergency rollback" "1" "$exit_code"
assert_contains "Rollback command executed to pre-shift snapshot (99/1)" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"
assert_contains "Emergency rollback logged" "$output" "TRIGGERING AUTOMATIC RESTORATION TO PRE-SHIFT SNAPSHOT"
assert_contains "Rollback verified successfully" "$output" "Rollback verified successfully: Pre-shift allocation safely restored"
assert_contains "Health caveat noted" "$output" "does not imply underlying application health recovery"

# ------------------------------------------------------------------------------
# Test 9: Excessive latency triggers emergency rollback to 99/1
# ------------------------------------------------------------------------------
echo "Test 9: Excessive latency (>3000ms) triggers emergency rollback to 99/1"
MOCK_LOG_DIR="$TEST_TMP_DIR/latency_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_high_latency"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 25 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 on excessive latency" "1" "$exit_code"
assert_contains "Rollback executed to pre-shift snapshot (99/1)" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"
assert_contains "Latency threshold failure logged" "$output" "exceeded maximum allowed threshold"

# ------------------------------------------------------------------------------
# Test 10: Critical Cloud Logging error triggers emergency rollback to 99/1
# ------------------------------------------------------------------------------
echo "Test 10: Critical log error (MongoServerSelectionError) triggers emergency rollback to 99/1"
MOCK_LOG_DIR="$TEST_TMP_DIR/log_error_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/inject_log_error"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 on database error log" "1" "$exit_code"
assert_contains "Rollback executed to pre-shift snapshot (99/1)" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"
assert_contains "Database error detection logged" "$output" "Critical database/SSL error detected in logs"

# ------------------------------------------------------------------------------
# Test 11: SIGINT interrupt during observation window triggers safe rollback (Requirement 4)
# ------------------------------------------------------------------------------
echo "Test 11: SIGINT interrupt during observation window triggers safe rollback (Requirement 4)"
MOCK_LOG_DIR="$TEST_TMP_DIR/sigint_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/simulate_sigint_in_sleep"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 50 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_contains "Process interrupt logged" "$output" "Process interrupted by signal!"
assert_contains "Rollback triggered on SIGINT restored 99/1" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"

# ------------------------------------------------------------------------------
# Test 12: Independent SIGTERM interrupt during observation window triggers safe rollback (Requirement 4)
# ------------------------------------------------------------------------------
echo "Test 12: Independent SIGTERM interrupt during observation window triggers safe rollback (Requirement 4)"
MOCK_LOG_DIR="$TEST_TMP_DIR/sigterm_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/simulate_sigterm_in_sleep"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 25 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_contains "Process interrupt logged on SIGTERM" "$output" "Process interrupted by signal!"
assert_contains "Rollback triggered on SIGTERM restored 99/1" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"

# ------------------------------------------------------------------------------
# Test 13: Actual traffic mismatch detection triggers rollback and restores 99/1
# ------------------------------------------------------------------------------
echo "Test 13: Actual traffic mismatch detection triggers rollback and restores 99/1 (Requirement 3, 6)"
MOCK_LOG_DIR="$TEST_TMP_DIR/mismatch_traffic_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/simulate_mismatched_traffic_on_verify"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 on traffic mismatch" "1" "$exit_code"
assert_contains "Mismatch detection logged" "$output" "Traffic allocation verification failed"
assert_contains "Emergency rollback command executed" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"

# Verify stateful simulated traffic file was restored to prod=99, cand=1
simulated_state=$(cat "$MOCK_LOG_DIR/simulated_traffic.json")
assert_contains "Final simulated state restored to prod=99%" "$simulated_state" '"percent": 99'
assert_contains "Final simulated state restored to cand=1%" "$simulated_state" '"percent": 1'

# ------------------------------------------------------------------------------
# Test 14: Strict JSON readiness validation blocks ready=false despite status=healthy
# ------------------------------------------------------------------------------
echo "Test 14: Strict JSON field validation rejects payload when ready=false despite status=healthy"
MOCK_LOG_DIR="$TEST_TMP_DIR/strict_json_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_readiness_ready_false"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with failure code 1 on ready=false" "1" "$exit_code"
assert_eq "Zero traffic mutations performed on ready=false" "0" "$mutation_count"
assert_contains "Ready false rejection logged" "$output" "ready field is false, expected true"

# ------------------------------------------------------------------------------
# Test 15: Stage 100 retains rollback protection throughout observation window (Requirement 5)
# ------------------------------------------------------------------------------
echo "Test 15: Stage 100 retains rollback protection throughout observation window (Requirement 5)"
MOCK_LOG_DIR="$TEST_TMP_DIR/stage_100_interrupt"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/simulate_sigint_in_sleep"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  BASELINE_FILE="$MOCK_LOG_DIR/baseline" \
  "$SCRIPT_UNDER_TEST" stage 100 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_contains "Stage 100 executed candidate=100" "$mutations" "--to-revisions=rideos-backend-api-00009-4gt=100"
assert_contains "Stage 100 interrupted during observation rolled back to 99/1" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"

# ------------------------------------------------------------------------------
# Test 16: Manual rollback restores pre-shift baseline safely without routing 100% to unhealthy revision
# ------------------------------------------------------------------------------
echo "Test 16: Manual rollback command restores pre-shift baseline and refuses 100% to unhealthy revision"
MOCK_LOG_DIR="$TEST_TMP_DIR/manual_rollback"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" rollback 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Manual rollback exits with code 0" "0" "$exit_code"
assert_contains "Manual rollback warns about unhealthy default" "$output" "Default target rideos-backend-api-00004-xcj=100 is known-unhealthy"
assert_contains "Manual rollback restores pre-shift baseline" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"

# ------------------------------------------------------------------------------
# Test 17: Update-traffic fails before mutation -> triggers recovery to pre-shift snapshot
# ------------------------------------------------------------------------------
echo "Test 17: Update-traffic command failure before mutation triggers safe rollback"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_update_before_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_update_traffic_before"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 after recovery" "1" "$exit_code"
assert_contains "Failure detected on command" "$output" "gcloud update-traffic command failed"
assert_contains "Rollback attempted to pre-shift snapshot (99/1)" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"
assert_contains "Rollback verified" "$output" "Rollback verified successfully"

# ------------------------------------------------------------------------------
# Test 18: Update-traffic fails after partial mutation -> triggers recovery to pre-shift snapshot
# ------------------------------------------------------------------------------
echo "Test 18: Update-traffic command failure after partial mutation triggers safe rollback (Requirement 3, 6)"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_update_after_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_update_traffic_after"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 25 --confirm 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with code 1 after recovery" "1" "$exit_code"
assert_contains "Failure detected and recovery logged" "$output" "gcloud update-traffic command failed"
assert_contains "Rollback executed to pre-shift snapshot (99/1)" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"
simulated_state=$(cat "$MOCK_LOG_DIR/simulated_traffic.json")
assert_contains "State restored to prod=99%" "$simulated_state" '"percent": 99'
assert_contains "State restored to cand=1%" "$simulated_state" '"percent": 1'

# ------------------------------------------------------------------------------
# Test 19: Rollback command failure -> reports CRITICAL_ROLLBACK_UNVERIFIED (Requirement 9)
# ------------------------------------------------------------------------------
echo "Test 19: Rollback command failure reports CRITICAL_ROLLBACK_UNVERIFIED (Requirement 9)"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_rollback_cmd_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_5xx"
touch "$MOCK_LOG_DIR/fail_rollback_cmd"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

assert_eq "Exits with code 2 on unverified rollback" "2" "$exit_code"
assert_contains "CRITICAL_ROLLBACK_UNVERIFIED reported" "$output" "CRITICAL_ROLLBACK_UNVERIFIED"

# ------------------------------------------------------------------------------
# Test 20: Rollback verification mismatch -> reports CRITICAL_ROLLBACK_UNVERIFIED (Requirement 9)
# ------------------------------------------------------------------------------
echo "Test 20: Rollback verification mismatch reports CRITICAL_ROLLBACK_UNVERIFIED (Requirement 9)"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_rollback_mismatch_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_5xx"
touch "$MOCK_LOG_DIR/simulate_rollback_verification_mismatch"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

assert_eq "Exits with code 2 on verification mismatch" "2" "$exit_code"
assert_contains "CRITICAL_ROLLBACK_UNVERIFIED reported on mismatch" "$output" "CRITICAL_ROLLBACK_UNVERIFIED"

# ------------------------------------------------------------------------------
# Test 21: Malformed traffic snapshot rejection before mutation (Requirement 7)
# ------------------------------------------------------------------------------
echo "Test 21: Malformed traffic snapshot aborts with zero mutations (Requirement 7)"
MOCK_LOG_DIR="$TEST_TMP_DIR/malformed_snapshot_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/simulate_malformed_traffic"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with code 1 on malformed snapshot" "1" "$exit_code"
assert_eq "Zero traffic mutations executed when snapshot fails" "0" "$mutation_count"
assert_contains "Safety gate logged" "$output" "CRITICAL SAFETY GATE: Failed to capture valid pre-shift traffic snapshot"

# ------------------------------------------------------------------------------
# Test 22: Existing 99/1 allocation snapshot capture (Requirement 1)
# ------------------------------------------------------------------------------
echo "Test 22: Existing 99/1 allocation snapshot capture (Requirement 1)"
MOCK_LOG_DIR="$TEST_TMP_DIR/snapshot_capture_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --dry-run 2>&1)
exit_code=$?
set -e

assert_eq "Exits cleanly with code 0" "0" "$exit_code"
assert_contains "Pre-shift snapshot captured as 99/1" "$output" "Pre-shift traffic snapshot captured: rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"
assert_contains "Pre-shift baseline preserved as 99/1" "$output" "Pre-shift baseline preserved: rideos-backend-api-00004-xcj=99,rideos-backend-api-00009-4gt=1"

# ------------------------------------------------------------------------------
# Test 23: Known-unhealthy rollback destination rejection (Requirement 8)
# ------------------------------------------------------------------------------
echo "Test 23: Known-unhealthy rollback destination rejection (Requirement 8)"
MOCK_LOG_DIR="$TEST_TMP_DIR/unhealthy_dest_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" rollback "rideos-backend-api-00004-xcj=100" 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with code 2 when attempting rollback to unhealthy destination" "2" "$exit_code"
assert_eq "Zero traffic mutations executed on rejected target" "0" "$mutation_count"
assert_contains "Rejection logged" "$output" "CRITICAL_SAFETY_REJECTION"
assert_contains "Rollback blocked logged" "$output" "CRITICAL_ROLLBACK_BLOCKED"

# ------------------------------------------------------------------------------
# Test 24: Future stable baseline behavior (Requirement 10)
# ------------------------------------------------------------------------------
echo "Test 24: Future stable baseline behavior (Requirement 10)"
MOCK_LOG_DIR="$TEST_TMP_DIR/baseline_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"
TEST_BASELINE_FILE="$MOCK_LOG_DIR/test_baseline"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  BASELINE_FILE="$TEST_BASELINE_FILE" \
  "$SCRIPT_UNDER_TEST" stage 100 --confirm 2>&1)
exit_code=$?
set -e

assert_eq "Stage 100 exits with code 0" "0" "$exit_code"
assert_contains "New baseline recorded in log" "$output" "NEW STABLE BASELINE ESTABLISHED: rideos-backend-api-00009-4gt"

if [[ -f "$TEST_BASELINE_FILE" ]]; then
  recorded_baseline=$(cat "$TEST_BASELINE_FILE" | tr -d '[:space:]')
  assert_eq "Baseline file contains candidate revision" "rideos-backend-api-00009-4gt" "$recorded_baseline"
else
  echo "  [FAIL] Baseline file was not created"
  FAIL_COUNT=$(( FAIL_COUNT + 1 ))
fi

# ------------------------------------------------------------------------------
# Test 26: Fresh-process loading of saved baseline & PROD_REV resolution (Task 3.4.2 Scenarios 1, 2)
# ------------------------------------------------------------------------------
echo "Test 26: Fresh-process loading of saved baseline & PROD_REV resolution (Task 3.4.2 Scenarios 1, 2)"
MOCK_LOG_DIR="$TEST_TMP_DIR/fresh_process_baseline"
mkdir -p "$MOCK_LOG_DIR"
FRESH_BASELINE_FILE="$MOCK_LOG_DIR/stable_baseline"
echo "rideos-backend-api-00009-4gt" > "$FRESH_BASELINE_FILE"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  BASELINE_FILE="$FRESH_BASELINE_FILE" \
  "$SCRIPT_UNDER_TEST" status 2>&1)
exit_code=$?
set -e

assert_eq "Fresh-process status exits with code 0" "0" "$exit_code"
assert_contains "Saved baseline loaded from file" "$output" "Loaded verified stable production baseline: rideos-backend-api-00009-4gt"
assert_contains "PROD_REV resolved to saved baseline" "$output" "Active Production Baseline: PROD_REV=rideos-backend-api-00009-4gt"

# ------------------------------------------------------------------------------
# Test 27: Staged rollout allocations use saved stable baseline across stages (Task 3.4.2 Scenarios 3, 4, 5, 6, 11)
# ------------------------------------------------------------------------------
echo "Test 27: Staged rollout allocations use saved stable baseline across stages (Task 3.4.2 Scenarios 3, 4, 5, 6, 11)"
MOCK_LOG_DIR="$TEST_TMP_DIR/staged_with_saved_baseline"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"
SAVED_BASELINE_FILE="$MOCK_LOG_DIR/active_baseline"
echo "rideos-backend-api-00009-4gt" > "$SAVED_BASELINE_FILE"

# Candidate for next deployment
NEW_CANDIDATE="rideos-backend-api-00010-xyz"

for stage in 5 25 50 100; do
  prod_pct=$(( 100 - stage ))
  set +e
  output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
    BASELINE_FILE="$SAVED_BASELINE_FILE" \
    CANDIDATE_REV="$NEW_CANDIDATE" \
    "$SCRIPT_UNDER_TEST" stage "$stage" --dry-run 2>&1)
  exit_code=$?
  set -e

  assert_eq "Stage $stage dry-run exits with code 0" "0" "$exit_code"
  if [[ "$stage" -eq 100 ]]; then
    assert_contains "Stage 100 sets candidate=100" "$output" "Planned traffic allocation: rideos-backend-api -> $NEW_CANDIDATE=100"
  else
    assert_contains "Stage $stage uses saved baseline 00009-4gt=$prod_pct and cand $NEW_CANDIDATE=$stage" "$output" "Planned traffic allocation: rideos-backend-api -> rideos-backend-api-00009-4gt=$prod_pct,$NEW_CANDIDATE=$stage"
  fi
  # Verify 00004-xcj is NOT present in planned traffic allocation
  planned_alloc=$(echo "$output" | grep "Planned traffic allocation" || echo "")
  if [[ "$planned_alloc" == *"rideos-backend-api-00004-xcj"* ]]; then
    echo "  [FAIL] Stage $stage accidentally allocated traffic to retired revision 00004-xcj"
    FAIL_COUNT=$(( FAIL_COUNT + 1 ))
  else
    echo "  [PASS] Stage $stage strictly excluded retired revision 00004-xcj from planned traffic"
    PASS_COUNT=$(( PASS_COUNT + 1 ))
  fi
done

# ------------------------------------------------------------------------------
# Test 28: Missing baseline fails closed when default revision is unhealthy (Task 3.4.2 Scenario 7)
# ------------------------------------------------------------------------------
echo "Test 28: Missing baseline fails closed when default revision is unhealthy (Task 3.4.2 Scenario 7)"
MOCK_LOG_DIR="$TEST_TMP_DIR/fail_closed_missing_baseline"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"
NON_EXISTENT_BASELINE="$MOCK_LOG_DIR/does_not_exist.baseline"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  BASELINE_FILE="$NON_EXISTENT_BASELINE" \
  REQUIRE_STABLE_BASELINE=1 \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with code 1 on missing baseline with unhealthy default" "1" "$exit_code"
assert_eq "Zero traffic mutations executed" "0" "$mutation_count"
assert_contains "Safety rejection logged" "$output" "CRITICAL_SAFETY_REJECTION"
assert_contains "Missing baseline logged" "$output" "Missing stable baseline file"

# ------------------------------------------------------------------------------
# Test 29: Invalid or unhealthy baseline is rejected (Task 3.4.2 Scenario 8)
# ------------------------------------------------------------------------------
echo "Test 29: Invalid or unhealthy baseline is rejected (Task 3.4.2 Scenario 8)"
# Part A: Stored baseline contains known-unhealthy revision 00004-xcj
MOCK_LOG_DIR="$TEST_TMP_DIR/unhealthy_stored_baseline"
mkdir -p "$MOCK_LOG_DIR"
UNHEALTHY_BASELINE_FILE="$MOCK_LOG_DIR/unhealthy_baseline"
echo "rideos-backend-api-00004-xcj" > "$UNHEALTHY_BASELINE_FILE"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  BASELINE_FILE="$UNHEALTHY_BASELINE_FILE" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with code 2 on unhealthy stored baseline" "2" "$exit_code"
assert_eq "Zero traffic mutations executed" "0" "$mutation_count"
assert_contains "Unhealthy baseline rejection logged" "$output" "CRITICAL_SAFETY_REJECTION"
assert_contains "Unhealthy revision listed in rejection" "$output" "KNOWN_UNHEALTHY_REVISIONS"

# Part B: Stored baseline contains invalid format
MOCK_LOG_DIR_B="$TEST_TMP_DIR/corrupt_stored_baseline"
mkdir -p "$MOCK_LOG_DIR_B"
CORRUPT_BASELINE_FILE="$MOCK_LOG_DIR_B/corrupt_baseline"
echo "CORRUPT@@@BAD_REVISION###" > "$CORRUPT_BASELINE_FILE"
touch "$MOCK_LOG_DIR_B/gcloud_mutations.log"

set +e
output_b=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR_B" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  BASELINE_FILE="$CORRUPT_BASELINE_FILE" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code_b=$?
set -e

mutation_count_b=$(wc -l < "$MOCK_LOG_DIR_B/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with code 2 on corrupt baseline format" "2" "$exit_code_b"
assert_eq "Zero traffic mutations executed on corrupt format" "0" "$mutation_count_b"
assert_contains "Corrupt baseline rejection logged" "$output_b" "CRITICAL_SAFETY_REJECTION"
assert_contains "Format error reported" "$output_b" "does not match valid Cloud Run revision format"

# ------------------------------------------------------------------------------
# Test 30: Manual rollback uses validated stable baseline (Task 3.4.2 Scenario 9)
# ------------------------------------------------------------------------------
echo "Test 30: Manual rollback uses validated stable baseline (Task 3.4.2 Scenario 9)"
MOCK_LOG_DIR="$TEST_TMP_DIR/manual_rollback_saved_baseline"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"
SAVED_BASELINE_FILE="$MOCK_LOG_DIR/saved_baseline"
echo "rideos-backend-api-00009-4gt" > "$SAVED_BASELINE_FILE"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  BASELINE_FILE="$SAVED_BASELINE_FILE" \
  CANDIDATE_REV="rideos-backend-api-00010-xyz" \
  "$SCRIPT_UNDER_TEST" rollback 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Manual rollback exits with code 0" "0" "$exit_code"
assert_contains "Rollback targets validated stable baseline 00009-4gt=100" "$mutations" "--to-revisions=rideos-backend-api-00009-4gt=100"
assert_contains "Rollback logs safe destination" "$output" "Executing manual rollback to verified safe destination: rideos-backend-api-00009-4gt=100"

# ------------------------------------------------------------------------------
# Test 31: Emergency restoration explicitly reports degraded availability (Task 3.4.2 Scenario 10)
# ------------------------------------------------------------------------------
echo "Test 31: Emergency restoration explicitly reports degraded availability (Task 3.4.2 Scenario 10)"
MOCK_LOG_DIR="$TEST_TMP_DIR/recovery_policy_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/fail_5xx"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  "$SCRIPT_UNDER_TEST" stage 5 --confirm 2>&1)
exit_code=$?
set -e

assert_eq "Exits with code 1 on emergency rollback" "1" "$exit_code"
assert_contains "Degraded availability alert logged" "$output" "DEGRADED_AVAILABILITY_ALERT"
assert_contains "Traffic restoration distinction logged" "$output" "TRAFFIC_RESTORATION_ONLY: Restoring traffic distribution DOES NOT equal application health recovery"
assert_contains "Degraded service warning present" "$output" "Production service availability remains degraded until a verified healthy revision is established"

# ------------------------------------------------------------------------------
# Test 32: Baseline persistence survives fresh process invocation & atomic file replacement (Task 3.4.2 Scenarios 1, 2)
# ------------------------------------------------------------------------------
echo "Test 32: Baseline persistence survives fresh process invocation & atomic file replacement (Task 3.4.2 Scenarios 1, 2)"
MOCK_LOG_DIR="$TEST_TMP_DIR/atomic_persistence_test"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"
PERSIST_BASELINE="$MOCK_LOG_DIR/persisted.baseline"

# 1. Run stage 100 with confirm to establish baseline
set +e
output_promo=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  BASELINE_FILE="$PERSIST_BASELINE" \
  "$SCRIPT_UNDER_TEST" stage 100 --confirm 2>&1)
set -e

assert_contains "Establish baseline logged" "$output_promo" "NEW STABLE BASELINE ESTABLISHED: rideos-backend-api-00009-4gt"
assert_eq "Baseline file exists" "true" "$([[ -f "$PERSIST_BASELINE" ]] && echo true || echo false)"

# 2. In a completely separate, clean subshell/process invocation, load the baseline
set +e
output_fresh=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="$MOCK_BIN/sleep" MOCK_LOG_DIR="$MOCK_LOG_DIR" GLOBAL_MUTATIONS_LOG="$GLOBAL_MUTATIONS_LOG" \
  BASELINE_FILE="$PERSIST_BASELINE" \
  "$SCRIPT_UNDER_TEST" status 2>&1)
exit_code_fresh=$?
set -e

assert_eq "Fresh process status check exits 0" "0" "$exit_code_fresh"
assert_contains "Fresh process loaded baseline" "$output_fresh" "Loaded verified stable production baseline: rideos-backend-api-00009-4gt"
assert_contains "Fresh process PROD_REV is baseline" "$output_fresh" "Active Production Baseline: PROD_REV=rideos-backend-api-00009-4gt"

# ------------------------------------------------------------------------------
# Test 25: Master Invariant: No automatic 00004-xcj=100 rollback across entire suite (Requirement 11)
# ------------------------------------------------------------------------------
echo "Test 25: Master Invariant: Global assertion across all test runs (Requirement 11)"
forbidden_calls=$(grep -c -- '--to-revisions=rideos-backend-api-00004-xcj=100' "$GLOBAL_MUTATIONS_LOG" || true)
assert_eq "Zero commands executed --to-revisions=rideos-backend-api-00004-xcj=100 across entire test suite" "0" "$forbidden_calls"

echo ""
echo "=================================================================="
echo "📊 TEST RESULTS: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "=================================================================="

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
