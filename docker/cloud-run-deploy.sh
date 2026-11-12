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
  "rideos-redis-host"
  "rideos-jwt-secret"
  "rideos-jwt-refresh-secret"
  "rideos-google-routes-api-key"
)

echo "Auditing required production secrets in Secret Manager..."
MISSING_SECRETS=()

for SECRET in "${REQUIRED_SECRETS[@]}"; do
  if ! gcloud secrets describe "${SECRET}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
    MISSING_SECRETS+=("${SECRET} (missing secret)")
  else
    # Check if there is at least one ENABLED version
    ENABLED_VERSIONS=$(gcloud secrets versions list "${SECRET}" --project="${PROJECT_ID}" --filter="state=ENABLED" --format="value(name)" 2>/dev/null || echo "")
    if [[ -z "${ENABLED_VERSIONS}" ]]; then
      MISSING_SECRETS+=("${SECRET} (no enabled version)")
    fi
  fi
done

if [[ ${#MISSING_SECRETS[@]} -gt 0 ]]; then
  echo "❌ CRITICAL SAFETY GATE: Deployment blocked by missing production secrets."
  echo "The following secrets are missing or lack enabled versions in Secret Manager (${PROJECT_ID}):"
  for S in "${MISSING_SECRETS[@]}"; do
    echo "  - ${S}"
  done
  echo ""
  echo "Production safety rules forbid deploying with fake credentials or 127.0.0.1 URLs."
  echo "To provision secrets, run:"
  echo "  gcloud secrets create rideos-mongo-uri --data-file=/path/to/mongo_uri.txt"
  echo "  gcloud secrets create rideos-redis-host --data-file=/path/to/redis_host.txt"
  echo "  gcloud secrets create rideos-jwt-secret --data-file=/path/to/jwt_secret.txt"
  echo "  gcloud secrets create rideos-jwt-refresh-secret --data-file=/path/to/jwt_refresh_secret.txt"
  echo "  gcloud secrets create rideos-google-routes-api-key --data-file=/path/to/routes_key.txt"
  exit 1
fi

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

# 8. Domain Mapping for api.rideos.ai
echo "Configuring custom domain mapping for api.rideos.ai..."
if ! gcloud beta run domain-mappings describe --domain="api.rideos.ai" --region="${REGION}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  echo "Creating domain mapping: api.rideos.ai -> ${SERVICE_NAME}..."
  gcloud beta run domain-mappings create \
    --service="${SERVICE_NAME}" \
    --domain="api.rideos.ai" \
    --region="${REGION}" \
    --project="${PROJECT_ID}" || echo "Note: Domain mapping creation may require DNS domain ownership verification in Google Search Console."
fi

# 9. Health Verification with Strict Assertion & Retries
echo "Verifying health endpoint at ${SERVICE_URL}/api/v1/health..."
MAX_RETRIES=12
RETRY_DELAY=5
HEALTHY=false
LAST_STATUS="000"
LAST_CONTENT_TYPE=""
LAST_BODY=""

for i in $(seq 1 $MAX_RETRIES); do
  echo "Attempt $i of $MAX_RETRIES: Checking ${SERVICE_URL}/api/v1/health..."
  
  # Fetch headers and body safely
  HTTP_RESPONSE=$(curl -s -w "\n%{http_code}\n%{content_type}" "${SERVICE_URL}/api/v1/health" || echo -e "\n000\nerror")
  
  LAST_CONTENT_TYPE=$(echo "$HTTP_RESPONSE" | tail -n 1)
  LAST_STATUS=$(echo "$HTTP_RESPONSE" | tail -n 2 | head -n 1)
  LAST_BODY=$(echo "$HTTP_RESPONSE" | sed '$d' | sed '$d')
  
  if [[ "$LAST_STATUS" == "200" ]] && [[ "$LAST_CONTENT_TYPE" == *"application/json"* ]] && [[ "$LAST_BODY" == *"\"status\""* ]]; then
    echo "✅ Health check verified: HTTP 200 OK, Content-Type: ${LAST_CONTENT_TYPE}"
    echo "Payload: ${LAST_BODY}"
    HEALTHY=true
    break
  fi
  
  echo "Waiting ${RETRY_DELAY}s (Current Status: ${LAST_STATUS}, Content-Type: ${LAST_CONTENT_TYPE})..."
  sleep $RETRY_DELAY
done

if [[ "$HEALTHY" != "true" ]]; then
  echo "❌ CRITICAL FAILURE: Health check failed after $MAX_RETRIES attempts."
  echo "Last Status: ${LAST_STATUS}, Content-Type: ${LAST_CONTENT_TYPE}"
  echo "Last Body: ${LAST_BODY}"
  exit 1
fi

echo "🎉 Deployment completed and health-verified successfully."
