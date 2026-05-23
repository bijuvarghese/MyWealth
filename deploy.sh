#!/usr/bin/env bash
# deploy.sh — Deploy Firebase functions and/or hosting for MyWealth
#
# Usage:
#   ./deploy.sh              # deploy everything (functions + hosting)
#   ./deploy.sh functions    # deploy only Cloud Functions
#   ./deploy.sh hosting      # deploy only Hosting
#
# Prerequisites:
#   brew install firebase-cli   (or: npm install -g firebase-tools)
#   firebase login

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

TARGET="${1:-all}"

case "$TARGET" in
  all)       DEPLOY_ARGS="--only functions,hosting" ;;
  functions) DEPLOY_ARGS="--only functions" ;;
  hosting)   DEPLOY_ARGS="--only hosting" ;;
  *)
    echo "Usage: $0 [all|functions|hosting]"
    exit 1
    ;;
esac

# Make sure dependencies are current before deploying functions
if [[ "$TARGET" == "all" || "$TARGET" == "functions" ]]; then
  echo "→ Installing function dependencies..."
  (cd functions && npm ci)
fi

echo "→ Deploying: $TARGET"
firebase deploy $DEPLOY_ARGS --project mywealth-api-router

echo "✓ Done"
