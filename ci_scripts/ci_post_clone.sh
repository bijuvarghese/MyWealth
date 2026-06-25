#!/bin/sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOSITORY_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-}"

if [ -z "$REPOSITORY_ROOT" ] && [ -n "${CI_WORKSPACE:-}" ]; then
  if [ -d "$CI_WORKSPACE/repository" ]; then
    REPOSITORY_ROOT="$CI_WORKSPACE/repository"
  else
    REPOSITORY_ROOT="$CI_WORKSPACE"
  fi
fi

if [ -z "$REPOSITORY_ROOT" ]; then
  REPOSITORY_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

PLIST_PATH="$REPOSITORY_ROOT/MyWealth/GoogleService-Info.plist"

if [ -z "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" ]; then
  echo "Missing GOOGLE_SERVICE_INFO_PLIST_BASE64"
  exit 1
fi

mkdir -p "$(dirname "$PLIST_PATH")"
if echo "$GOOGLE_SERVICE_INFO_PLIST_BASE64" | base64 --decode > "$PLIST_PATH" 2>/dev/null; then
  :
else
  echo "$GOOGLE_SERVICE_INFO_PLIST_BASE64" | base64 -D > "$PLIST_PATH"
fi
plutil -lint "$PLIST_PATH"
