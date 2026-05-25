#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SERVICE_NAME="${SERVICE_NAME:-mywealth-cache-check}"
PROJECT_ID="${PROJECT_ID:-mywealth-api-router}"
REGION="${REGION:-us-central1}"
REPOSITORY="${REPOSITORY:-cloud-run-source-deploy}"
IMAGE="us-central1-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${SERVICE_NAME}:latest"

if [[ -z "${RUN_CHECK_TOKEN:-}" ]]; then
  echo "RUN_CHECK_TOKEN must be set before deployment." >&2
  exit 1
fi

if [[ -z "${SLACK_WEBHOOK_URL:-}" ]]; then
  echo "SLACK_WEBHOOK_URL must be set before deployment." >&2
  exit 1
fi

echo "Building container image: $IMAGE"
gcloud builds submit "$PROJECT_ROOT" \
  --tag "$IMAGE" \
  --project "$PROJECT_ID" \
  --file "$PROJECT_ROOT/cloud-run/cache-check-service/Dockerfile"

echo "Deploying Cloud Run service: $SERVICE_NAME"
gcloud run deploy "$SERVICE_NAME" \
  --image "$IMAGE" \
  --platform managed \
  --region "$REGION" \
  --project "$PROJECT_ID" \
  --allow-unauthenticated \
  --set-env-vars "RUN_CHECK_TOKEN=${RUN_CHECK_TOKEN},SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}"

echo
echo "Deployment complete."
echo "Health check: GET /healthz"
echo "Run check: POST /run with header 'Authorization: Bearer ${RUN_CHECK_TOKEN}'"
