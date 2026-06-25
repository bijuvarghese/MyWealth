#!/bin/sh
set -euo pipefail

PLIST_PATH="$CI_WORKSPACE/MyWealth/MyWealth/GoogleService-Info.plist"

if [ -z "${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}" ]; then
  echo "Missing GOOGLE_SERVICE_INFO_PLIST_BASE64"
  exit 1
fi

mkdir -p "$(dirname "$PLIST_PATH")"
echo "$GOOGLE_SERVICE_INFO_PLIST_BASE64" | base64 --decode > "$PLIST_PATH"
plutil -lint "$PLIST_PATH"
