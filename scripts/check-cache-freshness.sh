#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INFO_PLIST="$PROJECT_ROOT/MyWealth/Info.plist"

threshold_seconds=$((8 * 60 * 60))
declare -a checks=("exchange-rate:ExchangeRateProxyURL" "metal-price:MetalPriceProxyURL")
custom_url=""
declare -a report_lines=()

usage() {
  cat <<'EOF'
Usage: scripts/check-cache-freshness.sh [--exchange-only | --metal-only] [--threshold-hours N] [--url URL]

Checks the Firebase cache endpoint responses, reads cacheTimestamp from the JSON
payloads, and exits non-zero if any checked cache is older than the threshold.

Options:
  --exchange-only        Check only the exchange-rate endpoint
  --metal-only           Check only the metal-price endpoint
  --threshold-hours N    Maximum allowed cache age in hours (default: 8)
  --url URL              Override the endpoint URL for a single-endpoint check

Slack:
  If SLACK_WEBHOOK_URL is set, the script posts the full run summary to Slack
  after every run, whether the result is OK, WARNING, or CRITICAL.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --exchange-only)
      checks=("exchange-rate:ExchangeRateProxyURL")
      shift
      ;;
    --metal-only)
      checks=("metal-price:MetalPriceProxyURL")
      shift
      ;;
    --threshold-hours)
      threshold_seconds=$(("$2" * 60 * 60))
      shift 2
      ;;
    --url)
      custom_url="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -n "$custom_url" && "${#checks[@]}" -ne 1 ]]; then
  echo "CRITICAL: --url can only be used with --exchange-only or --metal-only" >&2
  exit 2
fi

if [[ -z "$custom_url" && ! -f "$INFO_PLIST" ]]; then
  echo "CRITICAL: Info.plist not found at $INFO_PLIST" >&2
  exit 2
fi

check_endpoint() {
  local label="$1"
  local proxy_key="$2"
  local url="$3"
  local tmp_body
  local http_code
  local node_script
  local analysis
  local status

  tmp_body="$(mktemp)"
  trap 'rm -f "$tmp_body"' RETURN

  if ! http_code="$(
    curl -sS \
      --connect-timeout 10 \
      --max-time 20 \
      -H 'Accept: application/json' \
      -o "$tmp_body" \
      -w '%{http_code}' \
      "$url"
  )"; then
    echo "CRITICAL: Failed to reach $label endpoint at $url"
    return 2
  fi

  if [[ "$http_code" != "200" ]]; then
    echo "CRITICAL: $label endpoint returned HTTP $http_code from $url"
    if [[ -s "$tmp_body" ]]; then
      echo "Response body:"
      sed -n '1,40p' "$tmp_body"
    fi
    return 2
  fi

  node_script='
const fs = require("fs");

const [label, thresholdArg, url, bodyPath] = process.argv.slice(1);
const thresholdSeconds = Number.parseInt(thresholdArg, 10);

try {
  const raw = fs.readFileSync(bodyPath, "utf8");
  const payload = JSON.parse(raw);
  const cacheTimestamp = payload.cacheTimestamp;

  function formatAge(totalSeconds) {
    const seconds = Math.abs(totalSeconds);
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);

    const parts = [];
    if (days > 0) parts.push(`${days}d`);
    if (hours > 0) parts.push(`${hours}h`);
    if (minutes > 0) parts.push(`${minutes}m`);
    if (parts.length === 0) parts.push("0m");
    return parts.slice(0, 2).join(" ");
  }

  function formatTimestamp(epochSeconds) {
    return new Intl.DateTimeFormat("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit",
      second: "2-digit",
      timeZone: "UTC",
      timeZoneName: "short",
    }).format(new Date(epochSeconds * 1000));
  }

  if (!Number.isInteger(cacheTimestamp) || cacheTimestamp <= 0) {
    console.log(`CRITICAL: ${label} response from ${url} is missing a valid cacheTimestamp`);
    process.exit(2);
  }

  const nowSeconds = Math.floor(Date.now() / 1000);
  const ageSeconds = nowSeconds - cacheTimestamp;
  const refreshedAtIso = new Date(cacheTimestamp * 1000).toISOString();
  const refreshedAtHuman = formatTimestamp(cacheTimestamp);
  const ageHuman = formatAge(ageSeconds);
  const thresholdHuman = formatAge(thresholdSeconds);
  const providerDate = payload.date ?? payload.timestamp ?? null;
  const rateCount = payload.rates && typeof payload.rates === "object"
    ? Object.keys(payload.rates).length
    : 0;

  if (ageSeconds < 0) {
    console.log(`WARNING: ${label} cacheTimestamp is in the future. refreshedAt=${refreshedAtHuman} (${refreshedAtIso}) age=${ageHuman}`);
    process.exit(1);
  }

  if (ageSeconds > thresholdSeconds) {
    console.log(`CRITICAL: ${label} cache is stale. age=${ageHuman} threshold=${thresholdHuman} refreshedAt=${refreshedAtHuman} (${refreshedAtIso}) rateCount=${rateCount} providerMarker=${providerDate}`);
    process.exit(2);
  }

  console.log(`OK: ${label} cache is fresh. age=${ageHuman} threshold=${thresholdHuman} refreshedAt=${refreshedAtHuman} (${refreshedAtIso}) rateCount=${rateCount} providerMarker=${providerDate}`);
} catch (error) {
  console.log(`CRITICAL: Unable to parse ${label} response from ${url}: ${error.message}`);
  process.exit(2);
}
'

  if analysis="$(
    node -e "$node_script" "$label" "$threshold_seconds" "$url" "$tmp_body"
  )"; then
    status=0
  else
    status=$?
  fi

  report_lines+=("$analysis")
  echo "$analysis"
  return "$status"
}

send_slack_report() {
  local webhook_url="$1"
  local overall_status="$2"
  local summary
  local color
  local emoji
  local status_label
  local text
  local payload

  case "$overall_status" in
    0)
      status_label="OK"
      emoji=":white_check_mark:"
      color="good"
      ;;
    1)
      status_label="WARNING"
      emoji=":warning:"
      color="warning"
      ;;
    *)
      status_label="CRITICAL"
      emoji=":x:"
      color="danger"
      ;;
  esac

  summary="${emoji} MyWealth cache freshness check: ${status_label}"
  text="$summary"$'\n'"$(printf '%s\n' "${report_lines[@]}")"
  payload="$(
    node -e '
      const [text, color] = process.argv.slice(1);
      process.stdout.write(JSON.stringify({
        attachments: [{ color, text }],
      }));
    ' "$text" "$color"
  )"

  curl -sS \
    --connect-timeout 10 \
    --max-time 20 \
    -H 'Content-Type: application/json' \
    -d "$payload" \
    "$webhook_url" >/dev/null
}

overall_status=0

for entry in "${checks[@]}"; do
  IFS=":" read -r label proxy_key <<< "$entry"

  if [[ -n "$custom_url" ]]; then
    url="$custom_url"
  else
    url="$(plutil -extract "$proxy_key" raw "$INFO_PLIST")"
  fi

  if [[ -z "$url" ]]; then
    report_lines+=("CRITICAL: Missing endpoint URL for $label")
    echo "CRITICAL: Missing endpoint URL for $label"
    overall_status=2
    continue
  fi

  if ! check_endpoint "$label" "$proxy_key" "$url"; then
    status=$?
    if [[ "$status" -gt "$overall_status" ]]; then
      overall_status="$status"
    fi
  fi
done

if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
  if ! send_slack_report "${SLACK_WEBHOOK_URL}" "$overall_status"; then
    echo "WARNING: Failed to post cache freshness report to Slack webhook"
    if [[ "$overall_status" -lt 1 ]]; then
      overall_status=1
    fi
  fi
fi

exit "$overall_status"
