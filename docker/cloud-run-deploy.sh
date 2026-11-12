#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# RideOS AI — Google Cloud Run Production Backend Deployment Script
# ─────────────────────────────────────────────────────────────────────────────

PROJECT_ID="rideos-ai"
REGION="us-central1"
REPO_NAME="rideos-repo"
SERVICE_NAME="rideos-backend-api"

COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
IMAGE_TAG="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:${COMMIT_SHA}"
LATEST_TAG="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:latest"

echo "=================================================================="
echo "🚀 RideOS AI Cloud Run Production Backend Deployment"
echo "Project: ${PROJECT_ID} | Region: ${REGION} | Service: ${SERVICE_NAME}"
echo "Commit:  ${COMMIT_SHA} | Image:  ${IMAGE_TAG}"
echo "=================================================================="

# 1. Verify gcloud authenticated account and project
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
if [[ "${CURRENT_PROJECT}" != "${PROJECT_ID}" ]]; then
  echo "Setting active gcloud project to ${PROJECT_ID}..."
  gcloud config set project "${PROJECT_ID}"
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
  if ! gcloud secrets describe "${SECRET}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
    MISSING_SECRETS+=("${SECRET} (secret does not exist)")
  else
    # Check if there is at least one ENABLED version
    ENABLED_VERSIONS=$(gcloud secrets versions list "${SECRET}" --project="${PROJECT_ID}" --filter="state=ENABLED" --format="value(name)" 2>/dev/null || echo "")
    if [[ -z "${ENABLED_VERSIONS}" ]]; then
      MISSING_SECRETS+=("${SECRET} (no enabled version)")
    else
      # Validate secret content sanity without exposing or logging the secret value
      VAL=$(gcloud secrets versions access latest --secret="${SECRET}" --project="${PROJECT_ID}" 2>/dev/null || echo "")
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
  echo ""
  echo "Production safety rules forbid deploying with fake credentials, localhost URLs, or placeholders."
  echo "To provision secrets securely in Google Secret Manager, run:"
  echo "  gcloud secrets create rideos-mongo-uri --data-file=/path/to/mongo_uri.txt"
  echo "  gcloud secrets create rideos-jwt-secret --data-file=/path/to/jwt_secret.txt"
  echo "  gcloud secrets create rideos-jwt-refresh-secret --data-file=/path/to/jwt_refresh_secret.txt"
  echo "  gcloud secrets create rideos-google-routes-api-key --data-file=/path/to/routes_server_key.txt"
  echo "  gcloud secrets create rideos-google-maps-api-key --data-file=/path/to/maps_client_key.txt"
  exit 1
fi

echo "✅ All required production secrets validated in Secret Manager."

# 3. Ensure Artifact Registry repository exists
if ! gcloud artifacts repositories describe "${REPO_NAME}" --location="${REGION}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  echo "Creating Artifact Registry repository '${REPO_NAME}'..."
  gcloud artifacts repositories create "${REPO_NAME}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="RideOS AI Production Container Registry" \
    --project="${PROJECT_ID}"
fi

# 4. Build and Push Container using Google Cloud Build
echo "Submitting multi-stage build to Google Cloud Build..."
gcloud builds submit . \
  --config=docker/cloudbuild.backend.yaml \
  --substitutions=_IMAGE_TAG="${IMAGE_TAG}",_LATEST_TAG="${LATEST_TAG}" \
  --project="${PROJECT_ID}"

# 5. Deploy Cloud Run Service using declarative spec
echo "Deploying Cloud Run service..."
gcloud run services replace docker/cloud-run-service.yaml \
  --region="${REGION}" \
  --project="${PROJECT_ID}"

# 6. Allow Unauthenticated Ingress for Public API Endpoints
echo "Ensuring public ingress is permitted on ${SERVICE_NAME}..."
gcloud run services add-iam-policy-binding "${SERVICE_NAME}" \
  --region="${REGION}" \
  --member="allUsers" \
  --role="roles/run.invoker" \
  --project="${PROJECT_ID}"

# 7. Retrieve Service URL
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" --region="${REGION}" --project="${PROJECT_ID}" --format='value(status.url)')
echo "✅ Cloud Run deployment complete: ${SERVICE_URL}"

# 8. Production Readiness & Health Verification
echo "Verifying production readiness probe at ${SERVICE_URL}/api/v1/health/readiness..."
MAX_RETRIES=12
RETRY_DELAY=5
HEALTHY=false
LAST_STATUS="000"
LAST_CONTENT_TYPE=""
LAST_BODY=""

for i in $(seq 1 $MAX_RETRIES); do
  echo "Attempt $i of $MAX_RETRIES: Checking ${SERVICE_URL}/api/v1/health/readiness..."
  
  # Fetch headers and body safely
  HTTP_RESPONSE=$(curl -s -w "\n%{http_code}\n%{content_type}" "${SERVICE_URL}/api/v1/health/readiness" || echo -e "\n000\nerror")
  
  LAST_CONTENT_TYPE=$(echo "$HTTP_RESPONSE" | tail -n 1)
  LAST_STATUS=$(echo "$HTTP_RESPONSE" | tail -n 2 | head -n 1)
  LAST_BODY=$(echo "$HTTP_RESPONSE" | sed '$d' | sed '$d')
  
  if [[ "$LAST_STATUS" == "200" ]] && [[ "$LAST_CONTENT_TYPE" == *"application/json"* ]] && [[ "$LAST_BODY" == *"\"READY\""* ]] && [[ "$LAST_BODY" == *"\"ready\":true"* ]]; then
    echo "✅ Production readiness verified: HTTP 200 OK, Content-Type: ${LAST_CONTENT_TYPE}"
    echo "Payload: ${LAST_BODY}"
    HEALTHY=true
    break
  fi
  
  echo "Waiting ${RETRY_DELAY}s (Current Status: ${LAST_STATUS}, Content-Type: ${LAST_CONTENT_TYPE})..."
  sleep $RETRY_DELAY
done

if [[ "$HEALTHY" != "true" ]]; then
  echo "❌ CRITICAL FAILURE: Readiness check failed after $MAX_RETRIES attempts."
  echo "Last HTTP Status: ${LAST_STATUS}, Content-Type: ${LAST_CONTENT_TYPE}"
  echo "Last Response Body: ${LAST_BODY}"
  exit 1
fi

# 9. Custom Domain Mapping & DNS Status Audit
echo "Auditing custom domain mapping and DNS status for api.rideos.ai..."
DOMAIN_MAPPED=false
DNS_RESOLVED=false

if gcloud beta run domain-mappings describe --domain="api.rideos.ai" --region="${REGION}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  DOMAIN_MAPPED=true
  echo "✅ Cloud Run domain mapping exists: api.rideos.ai -> ${SERVICE_NAME}"
else
  echo "ℹ️  Domain mapping for api.rideos.ai not found in Cloud Run. Attempting registration..."
  if gcloud beta run domain-mappings create --service="${SERVICE_NAME}" --domain="api.rideos.ai" --region="${REGION}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
    DOMAIN_MAPPED=true
    echo "✅ Cloud Run domain mapping created."
  else
    echo "⚠️  Domain mapping registration requires DNS domain ownership verification in Google Search Console."
  fi
fi

# Check DNS resolution
if host "api.rideos.ai" >/dev/null 2>&1 || ping -c 1 -W 2 "api.rideos.ai" >/dev/null 2>&1; then
  DNS_RESOLVED=true
  echo "✅ DNS Resolution: api.rideos.ai successfully resolves."
else
  echo "ℹ️  DNS Resolution: api.rideos.ai is currently unmapped / NXDOMAIN."
  echo "   To complete custom domain mapping, add a CNAME record at your DNS provider:"
  echo "   Host: api.rideos.ai -> Target: ghs.googlehosted.com."
fi

echo ""
echo "=================================================================="
echo "🎉 DEPLOYMENT AUDIT VERDICT"
echo "=================================================================="
echo "1. Cloud Run Container Deployment: SUCCESS (${SERVICE_URL})"
echo "2. Container Readiness (MongoDB):  READY (HTTP 200 OK)"
if [[ "$DNS_RESOLVED" == "true" ]]; then
  echo "3. Custom Domain api.rideos.ai:     LIVE & VERIFIED"
else
  echo "3. Custom Domain api.rideos.ai:     PENDING_DNS_CONFIGURATION (service ready on direct Cloud Run URL)"
fi
echo "=================================================================="
