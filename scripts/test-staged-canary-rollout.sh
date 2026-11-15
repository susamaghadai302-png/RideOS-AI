#!/usr/bin/env bash
# ==============================================================================
# RideOS AI — Comprehensive Automated Safety & Rollback Test Suite
# ==============================================================================
# Tests staged-canary-rollout.sh using completely mocked commands:
# zero live gcloud mutations, zero production traffic shifting, portable timing.
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
# Setup Mock Harness for Safe Unit Testing
# ------------------------------------------------------------------------------

# Mock gcloud
cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
echo "$*" >> "$MOCK_LOG_DIR/gcloud_calls.log"

case "$*" in
  *"run services update-traffic"*)
    echo "$*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    exit 0
    ;;
  *"run services describe"*)
    echo "- percent: 100"
    echo "  revisionName: rideos-backend-api-00004-xcj"
    echo "- percent: 0"
    echo "  revisionName: rideos-backend-api-00009-4gt"
    echo "  tag: candidate"
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

# Mock sleep (instant execution, records sleep calls)
cat <<'EOF' > "$MOCK_BIN/sleep"
#!/usr/bin/env bash
echo "SLEEP:$1" >> "$MOCK_LOG_DIR/sleep.log"
if [[ -f "$MOCK_LOG_DIR/simulate_sigint_in_sleep" ]]; then
  rm -f "$MOCK_LOG_DIR/simulate_sigint_in_sleep"
  # Send SIGINT to parent process (the rollout script)
  kill -INT "$PPID"
fi
exit 0
EOF
chmod +x "$MOCK_BIN/sleep"

# Mock curl (handles endpoints and injects scenarios)
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
  if [[ -f "$MOCK_LOG_DIR/fail_readiness" ]]; then
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
echo "Test 8: HTTP 5xx probe failure triggers emergency rollback to 100% prod"
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
assert_eq "Exits with code 1 after emergency rollback" "1" "$exit_code"
assert_contains "Rollback command executed to 100% prod" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"
assert_contains "Emergency rollback logged" "$output" "TRIGGERING AUTOMATIC EMERGENCY ROLLBACK"

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
# Test 11: SIGINT interrupt during observation window triggers emergency rollback
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
assert_contains "Rollback triggered on interrupt" "$mutations" "--to-revisions=rideos-backend-api-00004-xcj=100"

# ------------------------------------------------------------------------------
# Test 12: Stage 100 preserves rollback protection through observation window
# ------------------------------------------------------------------------------
echo "Test 12: Stage 100 retains rollback protection throughout observation window"
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
# Test 13: Manual rollback command works directly
# ------------------------------------------------------------------------------
echo "Test 13: Manual rollback command restores 100% production revision"
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

echo ""
echo "=================================================================="
echo "📊 TEST RESULTS: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "=================================================================="

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
