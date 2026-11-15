#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# RideOS AI — Cloud Run Deployment Safety & Traffic Preservation Test Suite
# ─────────────────────────────────────────────────────────────────────────────
# Verifies docker/cloud-run-deploy.sh and docker/cloud-run-service.yaml using
# isolated, stateful mock harnesses. Guarantees zero live cloud mutations.
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_SCRIPT="$REPO_ROOT/docker/cloud-run-deploy.sh"
SERVICE_YAML="$REPO_ROOT/docker/cloud-run-service.yaml"

TEST_TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/rideos_deploy_test_XXXXXX")
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

MOCK_BIN="$TEST_TMP_DIR/mock_bin"
mkdir -p "$MOCK_BIN"

PASS_COUNT=0
FAIL_COUNT=0

assert_eq() {
  local desc="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo -e "  \033[1;32m[PASS]\033[0m $desc"
    PASS_COUNT=$(( PASS_COUNT + 1 ))
  else
    echo -e "  \033[1;31m[FAIL]\033[0m $desc (Expected: '$expected', Got: '$actual')"
    FAIL_COUNT=$(( FAIL_COUNT + 1 ))
  fi
}

assert_contains() {
  local desc="$1"
  local haystack="$2"
  local needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo -e "  \033[1;32m[PASS]\033[0m $desc"
    PASS_COUNT=$(( PASS_COUNT + 1 ))
  else
    echo -e "  \033[1;31m[FAIL]\033[0m $desc (Substring '$needle' not found in output)"
    FAIL_COUNT=$(( FAIL_COUNT + 1 ))
  fi
}

assert_not_contains() {
  local desc="$1"
  local haystack="$2"
  local needle="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo -e "  \033[1;32m[PASS]\033[0m $desc"
    PASS_COUNT=$(( PASS_COUNT + 1 ))
  else
    echo -e "  \033[1;31m[FAIL]\033[0m $desc (Substring '$needle' should NOT be present)"
    FAIL_COUNT=$(( FAIL_COUNT + 1 ))
  fi
}

echo "=================================================================="
echo "🚀 RideOS AI — Deployment Configuration Drift & Safety Tests"
echo "=================================================================="

# ------------------------------------------------------------------------------
# Test 1: Existing 99/1 allocation is preserved in the deployment plan
# ------------------------------------------------------------------------------
echo "Test 1: Existing 99/1 allocation is preserved in the deployment plan"
MOCK_LOG_DIR="$TEST_TMP_DIR/test1"
mkdir -p "$MOCK_LOG_DIR"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
echo "$*" >> "$MOCK_LOG_DIR/gcloud_calls.log"
case "$*" in
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    if [[ "$*" == *"rideos-mongo-uri"* ]]; then
      echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    else
      echo "super_secret_production_secure_token_32chars_long_2026"
    fi
    exit 0
    ;;
  *"run services describe"*)
    cat <<'JSON'
{
  "apiVersion": "serving.knative.dev/v1",
  "kind": "Service",
  "metadata": { "name": "rideos-backend-api" },
  "status": {
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ],
    "url": "https://rideos-backend-api-aeoxwaaccq-uc.a.run.app"
  }
}
JSON
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" MOCK_LOG_DIR="$MOCK_LOG_DIR" "$DEPLOY_SCRIPT" 2>&1)
exit_code=$?
set -e

assert_eq "Exits safely with code 0 on plan" "0" "$exit_code"
assert_contains "Displays 99% production revision" "$output" "rideos-backend-api-00004-xcj: 99%"
assert_contains "Displays 1% candidate revision" "$output" "rideos-backend-api-00009-4gt: 1% (tag: candidate)"
assert_contains "Displays 100% total allocation" "$output" "Total Allocated Traffic: 100%"
assert_contains "Confirms preservation policy" "$output" "Existing live allocations (100%) strictly preserved"

# ------------------------------------------------------------------------------
# Test 2: No hardcoded 100/0 traffic reset in YAML or deployment scripts
# ------------------------------------------------------------------------------
echo "Test 2: No hardcoded 100/0 traffic reset in manifest or scripts"
yaml_content=$(cat "$SERVICE_YAML")
assert_not_contains "YAML does not hardcode 00004-xcj" "$yaml_content" "rideos-backend-api-00004-xcj"
assert_not_contains "YAML does not hardcode percent: 100" "$yaml_content" "percent: 100"
deploy_content=$(cat "$DEPLOY_SCRIPT")
assert_not_contains "Deploy script does not use services replace" "$deploy_content" "gcloud run services replace"

# ------------------------------------------------------------------------------
# Test 3: Dry-run performs zero cloud mutations
# ------------------------------------------------------------------------------
echo "Test 3: Dry-run performs zero cloud mutations"
MOCK_LOG_DIR="$TEST_TMP_DIR/test3"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
case "$*" in
  *"run deploy"*|*"builds submit"*|*"services update-traffic"*|*"services replace"*|*"repositories create"*)
    echo "MUTATION: $*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    exit 0
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"run services describe"*)
    cat <<'JSON'
{
  "status": {
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" MOCK_LOG_DIR="$MOCK_LOG_DIR" "$DEPLOY_SCRIPT" --dry-run 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Dry-run exits with code 0" "0" "$exit_code"
assert_eq "Zero mutations executed in dry-run" "0" "$mutation_count"
assert_contains "Safety Gate message present" "$output" "Safety Gate: Real deployment mutations require the explicit '--confirm' flag"

# ------------------------------------------------------------------------------
# Test 4: Missing confirmation blocks deployment even with --skip-build
# ------------------------------------------------------------------------------
echo "Test 4: Missing confirmation blocks deployment even with --skip-build"
MOCK_LOG_DIR="$TEST_TMP_DIR/test4"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" MOCK_LOG_DIR="$MOCK_LOG_DIR" "$DEPLOY_SCRIPT" --skip-build 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with code 0 on unconfirmed skip-build" "0" "$exit_code"
assert_eq "Zero mutations executed when --confirm is omitted" "0" "$mutation_count"
assert_contains "Safety gate triggered" "$output" "Zero cloud mutations performed"

# ------------------------------------------------------------------------------
# Test 5: Deployment uses verified no-traffic mechanism (--no-traffic --tag=candidate)
# ------------------------------------------------------------------------------
echo "Test 5: Deployment uses verified no-traffic mechanism"
MOCK_LOG_DIR="$TEST_TMP_DIR/test5"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

STATE_FILE="$MOCK_LOG_DIR/service.json"
cat <<'JSON' > "$STATE_FILE"
{
  "status": {
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ],
    "url": "https://rideos-backend-api-aeoxwaaccq-uc.a.run.app"
  }
}
JSON

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
STATE_FILE="$MOCK_LOG_DIR/service.json"
case "$*" in
  *"run deploy"*)
    echo "DEPLOY: $*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    # Update state file to include candidate with 0% traffic and tag candidate
    cat <<'JSON' > "$STATE_FILE"
{
  "status": {
    "latestCreatedRevisionName": "rideos-backend-api-00010-new",
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt" },
      { "percent": 0, "revisionName": "rideos-backend-api-00010-new", "tag": "candidate", "url": "https://candidate---rideos-backend-api-aeoxwaaccq-uc.a.run.app" }
    ],
    "url": "https://rideos-backend-api-aeoxwaaccq-uc.a.run.app"
  }
}
JSON
    exit 0
    ;;
  *"artifacts repositories describe"*)
    exit 0
    ;;
  *"artifacts docker images list"*)
    echo "image_present"
    exit 0
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"run services describe"*)
    if [[ "$*" == *"--format='value(status.traffic.filter(tag=candidate).url)'"* || "$*" == *'--format=value(status.traffic.filter(tag=candidate).url)'* ]]; then
      echo "https://candidate---rideos-backend-api-aeoxwaaccq-uc.a.run.app"
    elif [[ "$*" == *"--format='value(status.url)'"* || "$*" == *"--format=value(status.url)"* ]]; then
      echo "https://rideos-backend-api-aeoxwaaccq-uc.a.run.app"
    else
      cat "$STATE_FILE"
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

cat <<'EOF' > "$MOCK_BIN/curl"
#!/usr/bin/env bash
out_file=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) out_file="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[[ -n "$out_file" ]] && echo '{"status":"READY","ready":true,"dependencies":{"mongodb":{"status":"healthy"}}}' > "$out_file"
echo -e '{"status":"READY","ready":true,"dependencies":{"mongodb":{"status":"healthy"}}}\n200\napplication/json'
exit 0
EOF
chmod +x "$MOCK_BIN/curl"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="true" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$DEPLOY_SCRIPT" --confirm --skip-build 2>&1)
exit_code=$?
set -e

deploy_mutation=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Deployment exits with code 0" "0" "$exit_code"
assert_contains "Deployment command uses --no-traffic" "$deploy_mutation" "--no-traffic"
assert_contains "Deployment command uses --tag=candidate" "$deploy_mutation" "--tag=candidate"
assert_contains "Post-deployment traffic preservation verified" "$output" "Traffic allocations perfectly preserved"
assert_contains "Candidate Direct Health READY" "$output" "Candidate Direct Health:       READY"

# ------------------------------------------------------------------------------
# Test 6: Runtime configuration and Direct VPC egress preserved
# ------------------------------------------------------------------------------
echo "Test 6: Existing runtime configuration and Direct VPC egress preserved"
yaml_content=$(cat "$SERVICE_YAML")
assert_contains "Direct VPC network specified" "$yaml_content" 'run.googleapis.com/network-interfaces: '\''[{"network":"rideos-vpc","subnetwork":"rideos-cloudrun-subnet"}]'\'''
assert_contains "Direct VPC all-traffic egress specified" "$yaml_content" "run.googleapis.com/vpc-access-egress: all-traffic"
assert_contains "Execution environment gen2 specified" "$yaml_content" "run.googleapis.com/execution-environment: gen2"
assert_contains "Dedicated runtime service account preserved" "$yaml_content" "serviceAccountName: rideos-backend-runner@rideos-ai.iam.gserviceaccount.com"

# ------------------------------------------------------------------------------
# Test 7: Post-deployment traffic mismatch is detected and verified restoration attempted
# ------------------------------------------------------------------------------
echo "Test 7: Post-deployment traffic mismatch is detected and verified restoration attempted"
MOCK_LOG_DIR="$TEST_TMP_DIR/test7"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
case "$*" in
  *"run deploy"*)
    echo "DEPLOY" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    exit 0
    ;;
  *"services update-traffic"*)
    echo "RESTORE: $*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    touch "$MOCK_LOG_DIR/restored"
    exit 0
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"artifacts repositories describe"*)
    exit 0
    ;;
  *"artifacts docker images list"*)
    echo "image_present"
    exit 0
    ;;
  *"run services describe"*)
    if [[ -f "$MOCK_LOG_DIR/restored" ]]; then
      # Third call: after restoration, return pre-deployment 99/1 allocations
      cat <<'JSON'
{
  "status": {
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
    elif [[ ! -f "$MOCK_LOG_DIR/deployed" ]]; then
      touch "$MOCK_LOG_DIR/deployed"
      cat <<'JSON'
{
  "status": {
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
    else
      # Second call (post-deployment): simulate unwanted traffic drift (e.g. 100% on candidate)
      cat <<'JSON'
{
  "status": {
    "traffic": [
      { "percent": 0, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 100, "revisionName": "rideos-backend-api-00010-new", "tag": "candidate" }
    ]
  }
}
JSON
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="true" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$DEPLOY_SCRIPT" --confirm --skip-build 2>&1)
exit_code=$?
set -e

mutations=$(cat "$MOCK_LOG_DIR/gcloud_mutations.log")
assert_eq "Exits with error code 1 on traffic mismatch" "1" "$exit_code"
assert_contains "Mismatch error detected" "$output" "Traffic drift on revision rideos-backend-api-00004-xcj"
assert_contains "Restoration attempted" "$mutations" "RESTORE: run services update-traffic"
assert_contains "Restoration verified" "$output" "Emergency traffic restoration verified: Pre-deployment allocations successfully restored"

# ------------------------------------------------------------------------------
# Test 8: Unsafe deployment with inconsistent pre-deployment traffic is rejected
# ------------------------------------------------------------------------------
echo "Test 8: Unsafe deployment with inconsistent pre-deployment traffic is rejected"
MOCK_LOG_DIR="$TEST_TMP_DIR/test8"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
case "$*" in
  *"run deploy"*|*"builds submit"*)
    echo "UNSAFE_MUTATION: $*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    exit 0
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"run services describe"*)
    # Corrupt pre-deployment traffic summing to only 80%
    cat <<'JSON'
{
  "status": {
    "traffic": [
      { "percent": 70, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 10, "revisionName": "rideos-backend-api-00009-4gt" }
    ]
  }
}
JSON
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$DEPLOY_SCRIPT" --confirm --skip-build 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with code 1 on corrupt pre-deployment traffic" "1" "$exit_code"
assert_eq "Zero deploy mutations performed on corrupt traffic" "0" "$mutation_count"
assert_contains "Inconsistent traffic error logged" "$output" "Live Cloud Run traffic total is 80%, not 100%"

# ------------------------------------------------------------------------------
# Test 9: Failed deployment does not silently promote a revision
# ------------------------------------------------------------------------------
echo "Test 9: Failed deployment does not silently promote a revision"
MOCK_LOG_DIR="$TEST_TMP_DIR/test9"
mkdir -p "$MOCK_LOG_DIR"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
case "$*" in
  *"run deploy"*)
    echo "Simulated Cloud Run deploy network error" >&2
    exit 1
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"artifacts repositories describe"*)
    exit 0
    ;;
  *"artifacts docker images list"*)
    echo "image_present"
    exit 0
    ;;
  *"run services describe"*)
    cat <<'JSON'
{
  "status": {
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$DEPLOY_SCRIPT" --confirm --skip-build 2>&1)
exit_code=$?
set -e

assert_eq "Exits with non-zero failure code" "1" "$exit_code"
assert_contains "Deploy failure caught safely" "$output" "Simulated Cloud Run deploy network error"

# ------------------------------------------------------------------------------
# Test 10: Fail-closed pre-deployment inspection rejects describe command failure
# ------------------------------------------------------------------------------
echo "Test 10: Fail-closed pre-deployment inspection rejects describe command failure"
MOCK_LOG_DIR="$TEST_TMP_DIR/test10"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
case "$*" in
  *"run deploy"*|*"builds submit"*)
    echo "UNSAFE_MUTATION: $*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    exit 0
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"artifacts repositories describe"*)
    exit 0
    ;;
  *"run services describe"*)
    echo "ERROR: (gcloud.run.services.describe) PERMISSION_DENIED: The caller does not have permission" >&2
    exit 1
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$DEPLOY_SCRIPT" --confirm --skip-build 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with code 1 on describe failure" "1" "$exit_code"
assert_eq "Zero deploy mutations performed on describe failure" "0" "$mutation_count"
assert_contains "Permission error detected and blocked" "$output" "Cloud Run service describe failed due to authentication, network, or permission error"

# ------------------------------------------------------------------------------
# Test 11: Fail-closed pre-deployment inspection rejects malformed JSON
# ------------------------------------------------------------------------------
echo "Test 11: Fail-closed pre-deployment inspection rejects malformed JSON"
MOCK_LOG_DIR="$TEST_TMP_DIR/test11"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
case "$*" in
  *"run deploy"*|*"builds submit"*)
    echo "UNSAFE_MUTATION: $*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    exit 0
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"artifacts repositories describe"*)
    exit 0
    ;;
  *"run services describe"*)
    echo "{ malformed_json_without_closing_brackets: [ true, "
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$DEPLOY_SCRIPT" --confirm --skip-build 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Exits with code 1 on malformed JSON" "1" "$exit_code"
assert_eq "Zero deploy mutations performed on malformed JSON" "0" "$mutation_count"
assert_contains "Malformed JSON error detected" "$output" "Malformed Cloud Run service JSON detected"

# ------------------------------------------------------------------------------
# Test 12: Audit-only mode performs read-only checks with zero mutations
# ------------------------------------------------------------------------------
echo "Test 12: Audit-only mode performs read-only checks with zero mutations"
MOCK_LOG_DIR="$TEST_TMP_DIR/test12"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
case "$*" in
  *"run deploy"*|*"builds submit"*|*"services update-traffic"*|*"repositories create"*|*"config set project"*)
    echo "MUTATION: $*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    exit 0
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"artifacts repositories describe"*)
    exit 0
    ;;
  *"run services describe"*)
    cat <<'JSON'
{
  "status": {
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$DEPLOY_SCRIPT" --audit-only 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Audit-only exits with code 0" "0" "$exit_code"
assert_eq "Zero mutations executed in audit-only" "0" "$mutation_count"
assert_contains "Audit summary present" "$output" "AUDIT-ONLY COMPLETE: All production configurations verified"
assert_contains "Secret Manager passed" "$output" "Secret Manager:     PASSED"
assert_contains "Artifact Registry passed" "$output" "Artifact Registry:  PASSED"
assert_contains "Cloud Run Service passed" "$output" "Cloud Run Service:  PASSED"

# ------------------------------------------------------------------------------
# Test 13: Audit-only mode fails when Artifact Registry repository does not exist
# ------------------------------------------------------------------------------
echo "Test 13: Audit-only mode fails when Artifact Registry repository does not exist"
MOCK_LOG_DIR="$TEST_TMP_DIR/test13"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
case "$*" in
  *"repositories create"*|*"run deploy"*|*"builds submit"*)
    echo "UNSAFE_MUTATION: $*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    exit 0
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"artifacts repositories describe"*)
    exit 1
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$DEPLOY_SCRIPT" --audit-only 2>&1)
exit_code=$?
set -e

mutation_count=$(wc -l < "$MOCK_LOG_DIR/gcloud_mutations.log" | tr -d ' ')
assert_eq "Audit-only exits with code 1 on missing repository" "1" "$exit_code"
assert_eq "Zero repository create mutations performed" "0" "$mutation_count"
assert_contains "Artifact Registry failure reported" "$output" "Artifact Registry repository 'rideos-repo' not found in us-central1"

# ------------------------------------------------------------------------------
# Test 14: Post-deployment restoration verification failure reports CRITICAL_TRAFFIC_RESTORATION_UNVERIFIED
# ------------------------------------------------------------------------------
echo "Test 14: Post-deployment restoration verification failure reports CRITICAL_TRAFFIC_RESTORATION_UNVERIFIED"
MOCK_LOG_DIR="$TEST_TMP_DIR/test14"
mkdir -p "$MOCK_LOG_DIR"
touch "$MOCK_LOG_DIR/gcloud_mutations.log"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
case "$*" in
  *"run deploy"*)
    echo "DEPLOY" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    exit 0
    ;;
  *"services update-traffic"*)
    echo "RESTORE: $*" >> "$MOCK_LOG_DIR/gcloud_mutations.log"
    touch "$MOCK_LOG_DIR/restored"
    # Simulate update-traffic failing or completing with ambiguous state
    exit 1
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"artifacts repositories describe"*)
    exit 0
    ;;
  *"artifacts docker images list"*)
    echo "image_present"
    exit 0
    ;;
  *"run services describe"*)
    if [[ ! -f "$MOCK_LOG_DIR/deployed" ]]; then
      touch "$MOCK_LOG_DIR/deployed"
      cat <<'JSON'
{
  "status": {
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
    else
      # Post-deployment: drift state
      cat <<'JSON'
{
  "status": {
    "traffic": [
      { "percent": 0, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 100, "revisionName": "rideos-backend-api-00010-new", "tag": "candidate" }
    ]
  }
}
JSON
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="true" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$DEPLOY_SCRIPT" --confirm --skip-build 2>&1)
exit_code=$?
set -e

assert_eq "Exits with code 1 on unverified restoration" "1" "$exit_code"
assert_contains "Reports CRITICAL_TRAFFIC_RESTORATION_UNVERIFIED" "$output" "CRITICAL_TRAFFIC_RESTORATION_UNVERIFIED"

# ------------------------------------------------------------------------------
# Test 15: Post-deployment missing candidate URL fails deployment
# ------------------------------------------------------------------------------
echo "Test 15: Post-deployment missing candidate URL fails deployment"
MOCK_LOG_DIR="$TEST_TMP_DIR/test15"
mkdir -p "$MOCK_LOG_DIR"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
case "$*" in
  *"run deploy"*)
    exit 0
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"artifacts repositories describe"*)
    exit 0
    ;;
  *"artifacts docker images list"*)
    echo "image_present"
    exit 0
    ;;
  *"run services describe"*)
    if [[ ! -f "$MOCK_LOG_DIR/deployed" ]]; then
      touch "$MOCK_LOG_DIR/deployed"
      cat <<'JSON'
{
  "status": {
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
    else
      # Post-deployment: candidate tag exists with 0% traffic, but empty url
      cat <<'JSON'
{
  "status": {
    "latestCreatedRevisionName": "rideos-backend-api-00010-new",
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt" },
      { "percent": 0, "revisionName": "rideos-backend-api-00010-new", "tag": "candidate", "url": "" }
    ],
    "url": "https://rideos-backend-api-aeoxwaaccq-uc.a.run.app"
  }
}
JSON
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="true" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$DEPLOY_SCRIPT" --confirm --skip-build 2>&1)
exit_code=$?
set -e

assert_eq "Exits with code 1 on missing candidate URL" "1" "$exit_code"
assert_contains "Missing candidate URL error reported" "$output" "Candidate tagged URL is missing or empty"

# ------------------------------------------------------------------------------
# Test 16: Failed candidate readiness probe fails deployment and never prints READY
# ------------------------------------------------------------------------------
echo "Test 16: Failed candidate readiness probe fails deployment and never prints READY"
MOCK_LOG_DIR="$TEST_TMP_DIR/test16"
mkdir -p "$MOCK_LOG_DIR"

cat <<'EOF' > "$MOCK_BIN/gcloud"
#!/usr/bin/env bash
case "$*" in
  *"run deploy"*)
    exit 0
    ;;
  *"config get-value project"*)
    echo "rideos-ai"
    exit 0
    ;;
  *"secrets describe"*)
    exit 0
    ;;
  *"secrets versions list"*)
    echo "1"
    exit 0
    ;;
  *"secrets versions access"*)
    echo "mongodb+srv://user:pass@cluster.mongodb.net/rideos"
    exit 0
    ;;
  *"artifacts repositories describe"*)
    exit 0
    ;;
  *"artifacts docker images list"*)
    echo "image_present"
    exit 0
    ;;
  *"run services describe"*)
    if [[ ! -f "$MOCK_LOG_DIR/deployed" ]]; then
      touch "$MOCK_LOG_DIR/deployed"
      cat <<'JSON'
{
  "status": {
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt", "tag": "candidate" }
    ]
  }
}
JSON
    else
      cat <<'JSON'
{
  "status": {
    "latestCreatedRevisionName": "rideos-backend-api-00010-new",
    "traffic": [
      { "percent": 99, "revisionName": "rideos-backend-api-00004-xcj" },
      { "percent": 1, "revisionName": "rideos-backend-api-00009-4gt" },
      { "percent": 0, "revisionName": "rideos-backend-api-00010-new", "tag": "candidate", "url": "https://candidate---rideos-backend-api-aeoxwaaccq-uc.a.run.app" }
    ],
    "url": "https://rideos-backend-api-aeoxwaaccq-uc.a.run.app"
  }
}
JSON
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$MOCK_BIN/gcloud"

cat <<'EOF' > "$MOCK_BIN/curl"
#!/usr/bin/env bash
echo -e '{"status":"unhealthy","ready":false,"dependencies":{"mongodb":{"status":"unhealthy"}}}\n500\napplication/json'
exit 0
EOF
chmod +x "$MOCK_BIN/curl"

set +e
output=$(GCLOUD_CMD="$MOCK_BIN/gcloud" CURL_CMD="$MOCK_BIN/curl" SLEEP_CMD="true" MOCK_LOG_DIR="$MOCK_LOG_DIR" \
  "$DEPLOY_SCRIPT" --confirm --skip-build 2>&1)
exit_code=$?
set -e

assert_eq "Exits with code 1 on failed readiness probe" "1" "$exit_code"
assert_contains "Readiness probe failure logged" "$output" "Candidate readiness probe failed"
assert_not_contains "Does not print candidate READY" "$output" "Candidate Direct Health:       READY"

echo ""
echo "=================================================================="
echo "📊 DEPLOYMENT TEST RESULTS: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "=================================================================="

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi
exit 0
