#!/usr/bin/env bash
# ==============================================================================
# RideOS AI — Test Suite for Staged Canary Rollout Script
# ==============================================================================

set -euo pipefail

SCRIPT_UNDER_TEST="./scripts/staged-canary-rollout.sh"
PASS_COUNT=0
FAIL_COUNT=0

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

echo "Running Rollout Controller Tests..."

# Test 1: Bash syntax validation
echo "Test 1: Bash syntax validation"
if bash -n "$SCRIPT_UNDER_TEST"; then
  echo "  [PASS] bash -n exited cleanly"
  PASS_COUNT=$(( PASS_COUNT + 1 ))
else
  echo "  [FAIL] bash -n syntax error"
  FAIL_COUNT=$(( FAIL_COUNT + 1 ))
fi

# Test 2: Usage / Help output
echo "Test 2: Usage / Help output on invalid command"
set +e
output=$("$SCRIPT_UNDER_TEST" invalid-cmd 2>&1)
exit_code=$?
set -e
assert_eq "Exits with code 1 on invalid argument" "1" "$exit_code"
assert_contains "Usage string present in output" "$output" "Usage:"

# Test 3: Invalid stage number validation
echo "Test 3: Invalid stage number rejection"
set +e
output=$("$SCRIPT_UNDER_TEST" stage 99 2>&1)
exit_code=$?
set -e
assert_eq "Exits with code 1 on stage 99" "1" "$exit_code"
assert_contains "Reports invalid stage error" "$output" "Invalid stage '99'"

# Test 4: Safety gate prevents unconfirmed stage execution
echo "Test 4: Safety gate blocks execution without --confirm"
set +e
output=$("$SCRIPT_UNDER_TEST" stage 1 2>&1)
exit_code=$?
set -e
assert_eq "Exits safely with code 0 on blocked execution" "0" "$exit_code"
assert_contains "Safety Gate warning displayed" "$output" "Safety Gate: Production traffic change requires explicit confirmation"

# Test 5: Verify revision ID constants
echo "Test 5: Revision ID constants match current production & candidate"
prod_rev=$(grep '^PROD_REV=' "$SCRIPT_UNDER_TEST" | cut -d'"' -f2)
cand_rev=$(grep '^CANDIDATE_REV=' "$SCRIPT_UNDER_TEST" | cut -d'"' -f2)
assert_eq "PROD_REV matches rideos-backend-api-00004-xcj" "rideos-backend-api-00004-xcj" "$prod_rev"
assert_eq "CANDIDATE_REV matches rideos-backend-api-00009-4gt" "rideos-backend-api-00009-4gt" "$cand_rev"

echo "================================================="
echo "Test Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "================================================="

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
