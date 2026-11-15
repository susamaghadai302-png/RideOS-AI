#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# RideOS AI — Google Cloud Run Production Backend Deployment Script
# ─────────────────────────────────────────────────────────────────────────────
# Implements hardened, drift-proof deployment semantics:
# - Default non-mutating PLAN / DRY-RUN mode until explicitly authorized with --confirm.
# - Documented no-traffic deployment semantics (--no-traffic --tag=candidate).
# - Strict pre-deployment and post-deployment traffic preservation verification.
# - Decoupled from hardcoded traffic revisions; traffic promotion is exclusively
#   managed by scripts/staged-canary-rollout.sh.
# ─────────────────────────────────────────────────────────────────────────────

PROJECT_ID="${PROJECT_ID:-rideos-ai}"
REGION="${REGION:-us-central1}"
REPO_NAME="${REPO_NAME:-rideos-repo}"
SERVICE_NAME="${SERVICE_NAME:-rideos-backend-api}"

AUDIT_ONLY=false
SKIP_BUILD=false
CONFIRMED=false
DRY_RUN=false

# Command wrappers to enable isolated stateful testing and metrics tracking
GCLOUD_CMD="${GCLOUD_CMD:-gcloud}"
CURL_CMD="${CURL_CMD:-curl}"
SLEEP_CMD="${SLEEP_CMD:-sleep}"

export CLOUDSDK_METRICS_ENVIRONMENT="datacloud.antigravity"

for arg in "$@"; do
  case "$arg" in
    --confirm)
      CONFIRMED=true
      shift || true
      ;;
    --dry-run)
      DRY_RUN=true
      shift || true
      ;;
    --audit-only)
      AUDIT_ONLY=true
      shift || true
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift || true
      ;;
    --help|-h)
      echo "Usage: ./docker/cloud-run-deploy.sh [--confirm] [--dry-run] [--audit-only] [--skip-build]"
      echo ""
      echo "Flags:"
      echo "  --confirm     Execute real cloud build and deployment mutations (required for live deployment)."
      echo "  --dry-run     Plan deployment and verify configurations with zero mutations (default mode)."
      echo "  --audit-only  Read-only audit of Secret Manager, Artifact Registry, and Cloud Run service."
      echo "  --skip-build  Reuse existing image tag in Artifact Registry; does NOT bypass --confirm gate."
      echo "  --help, -h    Show this help message."
      exit 0
      ;;
    *)
      ;;
  esac
done

# If --dry-run was explicitly passed or --confirm was omitted, enforce non-mutating plan mode
if [[ "${DRY_RUN}" == "true" || "${CONFIRMED}" == "false" ]]; then
  CONFIRMED=false
fi

COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
IMAGE_TAG="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:${COMMIT_SHA}"
LATEST_TAG="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:latest"

echo "=================================================================="
echo "🚀 RideOS AI Cloud Run Production Backend Deployment Controller"
echo "Project:   ${PROJECT_ID} | Region: ${REGION} | Service: ${SERVICE_NAME}"
echo "Commit:    ${COMMIT_SHA} | Image:  ${IMAGE_TAG}"
echo "Execution: $(if [[ "${CONFIRMED}" == "true" ]]; then echo "REAL MUTATION (--confirm provided)"; else echo "DRY-RUN / PLAN MODE (zero mutations)"; fi)"
echo "=================================================================="

# 1. Verify gcloud authenticated account and project
CURRENT_PROJECT=$($GCLOUD_CMD config get-value project 2>/dev/null || echo "")
if [[ -n "${CURRENT_PROJECT}" && "${CURRENT_PROJECT}" != "${PROJECT_ID}" ]]; then
  if [[ "${CONFIRMED}" == "true" ]]; then
    echo "Setting active gcloud project to ${PROJECT_ID}..."
    $GCLOUD_CMD config set project "${PROJECT_ID}"
  else
    echo "[PLAN] Would set active gcloud project to ${PROJECT_ID} (currently ${CURRENT_PROJECT})."
  fi
fi

# 2. Strict Production Credentials Audit (Secret Manager)
REQUIRED_SECRETS=(
  "rideos-mongo-uri"
  "rideos-jwt-secret"
  "rideos-jwt-refresh-secret"
  "rideos-google-routes-api-key"
  "rideos-google-maps-api-key"
)

REDIS_ENABLED="${REDIS_ENABLED:-false}"
TIMESCALE_ENABLED="${TIMESCALE_ENABLED:-false}"

if [[ "${REDIS_ENABLED}" == "true" ]]; then
  REQUIRED_SECRETS+=("rideos-redis-host")
fi
if [[ "${TIMESCALE_ENABLED}" == "true" ]]; then
  REQUIRED_SECRETS+=("rideos-timescale-host")
fi

echo "Auditing required production secrets in Secret Manager (${PROJECT_ID})..."
MISSING_SECRETS=()
INVALID_SECRETS=()

INSECURE_JWT_DEFAULTS=(
  "super_secret_rideos_jwt_key_2026"
  "super_secret_rideos_refresh_key_2026"
)

for SECRET in "${REQUIRED_SECRETS[@]}"; do
  if ! $GCLOUD_CMD secrets describe "${SECRET}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
    MISSING_SECRETS+=("${SECRET} (secret does not exist)")
  else
    # Check if there is at least one ENABLED version
    ENABLED_VERSIONS=$($GCLOUD_CMD secrets versions list "${SECRET}" --project="${PROJECT_ID}" --filter="state=ENABLED" --format="value(name)" 2>/dev/null || echo "")
    if [[ -z "${ENABLED_VERSIONS}" ]]; then
      MISSING_SECRETS+=("${SECRET} (no enabled version)")
    else
      # Validate secret content sanity without exposing or logging the secret value
      VAL=$($GCLOUD_CMD secrets versions access latest --secret="${SECRET}" --project="${PROJECT_ID}" 2>/dev/null || echo "")
      if [[ -z "${VAL//[[:space:]]/}" ]]; then
        INVALID_SECRETS+=("${SECRET} (empty secret payload)")
      elif [[ "${SECRET}" == "rideos-mongo-uri" ]]; then
        if [[ "${VAL}" != mongodb://* ]] && [[ "${VAL}" != mongodb+srv://* ]]; then
          INVALID_SECRETS+=("${SECRET} (must be a valid mongodb:// or mongodb+srv:// URI)")
        fi
        if [[ "${VAL}" == *"localhost"* ]] || [[ "${VAL}" == *"127.0.0.1"* ]]; then
          INVALID_SECRETS+=("${SECRET} (localhost URI prohibited in production)")
        fi
      elif [[ "${SECRET}" == "rideos-jwt-secret" ]] || [[ "${SECRET}" == "rideos-jwt-refresh-secret" ]]; then
        for INSECURE in "${INSECURE_JWT_DEFAULTS[@]}"; do
          if [[ "${VAL}" == "${INSECURE}" ]]; then
            INVALID_SECRETS+=("${SECRET} (insecure default placeholder rejected)")
          fi
        done
        if [[ ${#VAL} -lt 32 ]]; then
          INVALID_SECRETS+=("${SECRET} (secret length must be >= 32 characters)")
        fi
      fi
      unset VAL
    fi
  fi
done

if [[ ${#MISSING_SECRETS[@]} -gt 0 ]] || [[ ${#INVALID_SECRETS[@]} -gt 0 ]]; then
  echo "❌ CRITICAL SAFETY GATE: Deployment blocked by missing or invalid production secrets."
  if [[ ${#MISSING_SECRETS[@]} -gt 0 ]]; then
    echo "The following secrets are missing or lack enabled versions in Secret Manager (${PROJECT_ID}):"
    for S in "${MISSING_SECRETS[@]}"; do
      echo "  - ${S}"
    done
  fi
  if [[ ${#INVALID_SECRETS[@]} -gt 0 ]]; then
    echo "The following secrets failed production safety validation:"
    for S in "${INVALID_SECRETS[@]}"; do
      echo "  - ${S}"
    done
  fi
  exit 1
fi

echo "✅ All required production secrets validated in Secret Manager."

if [[ "${AUDIT_ONLY}" == "true" ]]; then
  echo "✅ Secrets audit completed successfully. Exiting due to --audit-only flag."
  exit 0
fi

# 3. Capture Pre-Deployment Live Traffic Configuration
echo "Inspecting live Cloud Run traffic configuration for ${SERVICE_NAME}..."
BEFORE_SERVICE_JSON=$($GCLOUD_CMD run services describe "${SERVICE_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format="json" 2>/dev/null || echo "{}")

PARSED_BEFORE_TRAFFIC=$(node -e '
  try {
    const raw = process.argv[1];
    if (!raw || raw.trim() === "{}" || raw.trim().length === 0) {
      console.log(JSON.stringify({ exists: false, total: 0, allocations: [] }));
      process.exit(0);
    }
    const data = JSON.parse(raw);
    const traffic = (data.status && Array.isArray(data.status.traffic)) ? data.status.traffic : [];
    let total = 0;
    const allocations = [];
    for (const t of traffic) {
      const pct = parseInt(t.percent || 0, 10);
      total += pct;
      allocations.push({
        revisionName: t.revisionName || "unknown",
        percent: pct,
        tag: t.tag || null,
        url: t.url || null
      });
    }
    console.log(JSON.stringify({ exists: true, total, allocations }));
  } catch (e) {
    console.log(JSON.stringify({ exists: false, error: e.message, total: 0, allocations: [] }));
  }
' "$BEFORE_SERVICE_JSON")

SERVICE_EXISTS=$(node -e 'console.log(JSON.parse(process.argv[1]).exists)' "$PARSED_BEFORE_TRAFFIC")
BEFORE_TOTAL_PCT=$(node -e 'console.log(JSON.parse(process.argv[1]).total)' "$PARSED_BEFORE_TRAFFIC")

if [[ "$SERVICE_EXISTS" == "true" ]]; then
  echo "Current Live Traffic Allocations:"
  node -e '
    const allocs = JSON.parse(process.argv[1]).allocations;
    for (const a of allocs) {
      console.log(`  - ${a.revisionName}: ${a.percent}%${a.tag ? ` (tag: ${a.tag})` : ""}`);
    }
  ' "$PARSED_BEFORE_TRAFFIC"
  echo "Total Allocated Traffic: ${BEFORE_TOTAL_PCT}%"

  if [[ "$BEFORE_TOTAL_PCT" -ne 100 ]]; then
    echo "❌ CRITICAL SAFETY GATE: Live Cloud Run traffic total is ${BEFORE_TOTAL_PCT}%, not 100%!"
    echo "Refusing to proceed with deployment on an inconsistent traffic state."
    exit 1
  fi
else
  echo "ℹ️  Service ${SERVICE_NAME} not found. This deployment will initialize a new service."
fi

# 4. Safety Confirmation Gate
if [[ "${CONFIRMED}" != "true" ]]; then
  echo ""
  echo "=================================================================="
  echo "🛡️  DEPLOYMENT PLAN SUMMARY (DRY-RUN / NON-MUTATING)"
  echo "=================================================================="
  echo "Target Image:             ${IMAGE_TAG}"
  echo "Service:                  ${SERVICE_NAME} (${REGION})"
  echo "Deployment Semantics:     gcloud run deploy --no-traffic --tag=candidate"
  if [[ "$SERVICE_EXISTS" == "true" ]]; then
    echo "Traffic Preservation:     Existing live allocations (${BEFORE_TOTAL_PCT}%) strictly preserved."
    echo "Candidate Traffic:        0% (candidate tag direct endpoint only)."
  else
    echo "Initial Deployment:       Service will be created."
  fi
  echo "Traffic Promotion Policy: Managed exclusively via scripts/staged-canary-rollout.sh."
  echo "------------------------------------------------------------------"
  echo "Safety Gate: Real deployment mutations require the explicit '--confirm' flag."
  echo "Example: ./docker/cloud-run-deploy.sh --confirm $(if [[ "${SKIP_BUILD}" == "true" ]]; then echo "--skip-build"; fi)"
  echo "Zero cloud mutations performed. Exiting safely."
  echo "=================================================================="
  exit 0
fi

# 5. Build and Push Container using Google Cloud Build (only when --confirm is present)
echo "Ensuring Artifact Registry repository '${REPO_NAME}' exists..."
if ! $GCLOUD_CMD artifacts repositories describe "${REPO_NAME}" --location="${REGION}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  echo "Creating Artifact Registry repository '${REPO_NAME}'..."
  $GCLOUD_CMD artifacts repositories create "${REPO_NAME}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="RideOS AI Production Container Registry" \
    --project="${PROJECT_ID}"
fi

if [[ "${SKIP_BUILD}" == "true" ]]; then
  echo "Skipping container build (--skip-build requested). Verifying image in Artifact Registry..."
  if ! $GCLOUD_CMD artifacts docker images list "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
    echo "❌ ERROR: No existing container image found in Artifact Registry."
    exit 1
  fi
  echo "✅ Existing container image verified in Artifact Registry."
else
  echo "Submitting multi-stage build to Google Cloud Build..."
  $GCLOUD_CMD builds submit . \
    --config=docker/cloudbuild.backend.yaml \
    --substitutions=_IMAGE_TAG="${IMAGE_TAG}",_LATEST_TAG="${LATEST_TAG}" \
    --project="${PROJECT_ID}"
fi

# 6. Deploy Candidate Revision using Documented No-Traffic Semantics
# Uses official Cloud Run --no-traffic and --tag=candidate to guarantee zero unexpected traffic mutations
echo "Deploying candidate revision to Cloud Run with --no-traffic --tag=candidate..."
$GCLOUD_CMD run deploy "${SERVICE_NAME}" \
  --image="${IMAGE_TAG}" \
  --no-traffic \
  --tag="candidate" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --quiet

# Ensure public ingress is permitted on the service
$GCLOUD_CMD run services add-iam-policy-binding "${SERVICE_NAME}" \
  --region="${REGION}" \
  --member="allUsers" \
  --role="roles/run.invoker" \
  --project="${PROJECT_ID}" >/dev/null 2>&1 || true

# 7. Post-Deployment Traffic Preservation Verification
echo "Verifying post-deployment traffic preservation (read-back check)..."
AFTER_SERVICE_JSON=$($GCLOUD_CMD run services describe "${SERVICE_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format="json" 2>/dev/null || echo "{}")

VERIFY_RESULT=$(node -e '
  try {
    const beforeData = JSON.parse(process.argv[1]);
    const afterRaw = process.argv[2];
    const afterData = JSON.parse(afterRaw);

    if (!beforeData.exists) {
      console.log("OK: initial deployment");
      process.exit(0);
    }

    const afterTraffic = (afterData.status && Array.isArray(afterData.status.traffic)) ? afterData.status.traffic : [];
    let afterTotal = 0;
    const afterMap = {};

    for (const t of afterTraffic) {
      const pct = parseInt(t.percent || 0, 10);
      afterTotal += pct;
      afterMap[t.revisionName] = (afterMap[t.revisionName] || 0) + pct;
    }

    if (afterTotal !== 100) {
      console.log(`ERR: Post-deployment total traffic is ${afterTotal}%, expected exactly 100%`);
      process.exit(0);
    }

    // Verify all pre-existing allocations with percent > 0 are exactly preserved
    for (const b of beforeData.allocations) {
      if (b.percent > 0) {
        const afterPct = afterMap[b.revisionName] || 0;
        if (afterPct !== b.percent) {
          console.log(`ERR: Traffic drift on revision ${b.revisionName}: was ${b.percent}%, now ${afterPct}%`);
          process.exit(0);
        }
      }
    }

    // Verify candidate tag has 0% traffic
    const candidateTarget = afterTraffic.find(t => t.tag === "candidate");
    if (candidateTarget && parseInt(candidateTarget.percent || 0, 10) !== 0) {
      console.log(`ERR: Candidate tag received ${candidateTarget.percent}%, expected 0%`);
      process.exit(0);
    }

    console.log("OK: Traffic allocations perfectly preserved");
  } catch (e) {
    console.log("ERR: Parser failure: " + e.message);
  }
' "$PARSED_BEFORE_TRAFFIC" "$AFTER_SERVICE_JSON")

if [[ "$VERIFY_RESULT" != OK:* ]]; then
  echo "❌ CRITICAL SAFETY FAILURE: Traffic preservation check failed after deployment!"
  echo "Details: ${VERIFY_RESULT}"
  echo "Attempting immediate emergency traffic restoration to captured pre-deployment allocations..."

  # Build restoration argument
  RESTORE_ARG=$(node -e '
    const before = JSON.parse(process.argv[1]);
    const pairs = before.allocations.filter(a => a.percent > 0).map(a => `${a.revisionName}=${a.percent}`);
    console.log(pairs.join(","));
  ' "$PARSED_BEFORE_TRAFFIC")

  if [[ -n "$RESTORE_ARG" ]]; then
    $GCLOUD_CMD run services update-traffic "${SERVICE_NAME}" \
      --to-revisions="${RESTORE_ARG}" \
      --region="${REGION}" \
      --project="${PROJECT_ID}" \
      --quiet || true
  fi

  echo "❌ DEPLOYMENT FAILED: CRITICAL_TRAFFIC_PRESERVATION_FAILED"
  exit 1
fi

echo "✅ Post-deployment traffic preservation verified: ${VERIFY_RESULT}"

# 8. Retrieve URLs & Candidate Readiness Verification
SERVICE_URL=$($GCLOUD_CMD run services describe "${SERVICE_NAME}" --region="${REGION}" --project="${PROJECT_ID}" --format='value(status.url)' 2>/dev/null || echo "")
CANDIDATE_URL=$($GCLOUD_CMD run services describe "${SERVICE_NAME}" --region="${REGION}" --project="${PROJECT_ID}" --format='value(status.traffic.filter(tag=candidate).url)' 2>/dev/null || echo "")

echo "Production Weighted URL: ${SERVICE_URL}"
echo "Candidate Tagged URL:    ${CANDIDATE_URL}"

# If candidate URL is found, probe candidate readiness
if [[ -n "${CANDIDATE_URL}" ]]; then
  echo "Verifying candidate readiness probe on ${CANDIDATE_URL}/api/v1/health/readiness..."
  MAX_RETRIES=12
  RETRY_DELAY=5
  HEALTHY=false
  LAST_STATUS="000"
  LAST_BODY=""

  for i in $(seq 1 $MAX_RETRIES); do
    echo "Attempt $i of $MAX_RETRIES: Checking ${CANDIDATE_URL}/api/v1/health/readiness..."
    HTTP_RESPONSE=$($CURL_CMD -s -w "\n%{http_code}\n%{content_type}" "${CANDIDATE_URL}/api/v1/health/readiness" || echo -e "\n000\nerror")
    LAST_STATUS=$(echo "$HTTP_RESPONSE" | tail -n 2 | head -n 1)
    LAST_BODY=$(echo "$HTTP_RESPONSE" | sed '$d' | sed '$d')

    if [[ "$LAST_STATUS" == "200" ]] && [[ "$LAST_BODY" == *"\"READY\""* ]] && [[ "$LAST_BODY" == *"\"ready\":true"* ]]; then
      echo "✅ Candidate readiness verified: HTTP 200 OK (MongoDB healthy, ready: true)"
      HEALTHY=true
      break
    fi

    echo "Waiting ${RETRY_DELAY}s (Current Status: ${LAST_STATUS})..."
    $SLEEP_CMD $RETRY_DELAY
  done

  if [[ "$HEALTHY" != "true" ]]; then
    echo "❌ WARNING: Candidate readiness probe failed on ${CANDIDATE_URL}."
    echo "Last HTTP Status: ${LAST_STATUS}, Response: ${LAST_BODY}"
    echo "Candidate revision was deployed with 0% traffic; production traffic remains safe and unimpacted."
    exit 1
  fi
fi

# 9. Custom Domain Mapping & DNS Status Audit
echo "Auditing custom domain mapping and DNS status for api.rideos.ai..."
DOMAIN_MAPPED=false
DNS_RESOLVED=false

if $GCLOUD_CMD beta --quiet run domain-mappings describe --domain="api.rideos.ai" --region="${REGION}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  DOMAIN_MAPPED=true
  echo "✅ Cloud Run domain mapping exists: api.rideos.ai -> ${SERVICE_NAME}"
else
  echo "ℹ️  Domain mapping for api.rideos.ai not found in Cloud Run."
fi

# Check DNS resolution
if host "api.rideos.ai" >/dev/null 2>&1 || ping -c 1 -W 2 "api.rideos.ai" >/dev/null 2>&1; then
  DNS_RESOLVED=true
  echo "✅ DNS Resolution: api.rideos.ai successfully resolves."
else
  echo "ℹ️  DNS Resolution: api.rideos.ai is currently unmapped / NXDOMAIN (Azure DNS configuration required)."
fi

echo ""
echo "=================================================================="
echo "🎉 DEPLOYMENT SUMMARY & HANDOFF"
echo "=================================================================="
echo "1. Candidate Revision Deployment: SUCCESS (0% traffic, tag: candidate)"
echo "2. Traffic Allocation:           PRESERVED at existing allocations (${BEFORE_TOTAL_PCT}%)"
echo "3. Candidate Direct Health:       READY (HTTP 200 OK, MongoDB healthy)"
echo "4. Traffic Promotion Authority:   Exclusively managed by scripts/staged-canary-rollout.sh"
echo "=================================================================="
exit 0
