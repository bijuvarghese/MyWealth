#!/usr/bin/env node

"use strict";

const fs = require("fs");
const path = require("path");

const PROJECT_ROOT = path.resolve(__dirname, "..");
const INFO_PLIST = path.join(PROJECT_ROOT, "MyWealth", "Info.plist");
const DEFAULT_THRESHOLD_SECONDS = 8 * 60 * 60;
const DEFAULT_CHECKS = [
  { label: "exchange-rate", envKey: "EXCHANGE_RATE_PROXY_URL", plistKey: "ExchangeRateProxyURL" },
  { label: "metal-price", envKey: "METAL_PRICE_PROXY_URL", plistKey: "MetalPriceProxyURL" },
];

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

function usage() {
  return `Usage: scripts/check-cache-freshness.sh [--exchange-only | --metal-only] [--threshold-hours N] [--url URL]

Checks the Firebase cache endpoint responses, reads cacheTimestamp from the JSON
payloads, and exits non-zero if any checked cache is older than the threshold.

Options:
  --exchange-only        Check only the exchange-rate endpoint
  --metal-only           Check only the metal-price endpoint
  --threshold-hours N    Maximum allowed cache age in hours (default: 8)
  --url URL              Override the endpoint URL for a single-endpoint check

Slack:
  If SLACK_WEBHOOK_URL is set, the script posts the full run summary to Slack
  only when the result is CRITICAL (for example, an API failure or stale cache).`;
}

function parseArgs(argv) {
  const options = {
    thresholdSeconds: DEFAULT_THRESHOLD_SECONDS,
    checks: [...DEFAULT_CHECKS],
    customUrl: "",
    showHelp: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    switch (arg) {
      case "--exchange-only":
        options.checks = [DEFAULT_CHECKS[0]];
        break;
      case "--metal-only":
        options.checks = [DEFAULT_CHECKS[1]];
        break;
      case "--threshold-hours": {
        const value = argv[index + 1];
        if (!value || Number.isNaN(Number(value))) {
          throw new Error("--threshold-hours requires a numeric value");
        }
        options.thresholdSeconds = Math.floor(Number(value) * 60 * 60);
        index += 1;
        break;
      }
      case "--url": {
        const value = argv[index + 1];
        if (!value) {
          throw new Error("--url requires a value");
        }
        options.customUrl = value;
        index += 1;
        break;
      }
      case "--help":
      case "-h":
        options.showHelp = true;
        break;
      default:
        throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (options.customUrl && options.checks.length !== 1) {
    throw new Error("--url can only be used with --exchange-only or --metal-only");
  }

  return options;
}

function readProxyUrlFromPlist(plistKey) {
  if (!fs.existsSync(INFO_PLIST)) {
    throw new Error(`Info.plist not found at ${INFO_PLIST}`);
  }

  const plist = fs.readFileSync(INFO_PLIST, "utf8");
  const pattern = new RegExp(`<key>${plistKey}</key>\\s*<string>([^<]+)</string>`);
  const match = plist.match(pattern);
  return match ? match[1].trim() : "";
}

function resolveUrl(check, customUrl, env) {
  if (customUrl) {
    return customUrl;
  }

  const envValue = env[check.envKey];
  if (envValue) {
    return envValue;
  }

  return readProxyUrlFromPlist(check.plistKey);
}

async function fetchJson(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20_000);

  try {
    const response = await fetch(url, {
      headers: { Accept: "application/json" },
      signal: controller.signal,
    });
    const text = await response.text();

    return {
      ok: response.ok,
      status: response.status,
      text,
    };
  } finally {
    clearTimeout(timeout);
  }
}

function evaluatePayload(label, url, payload, thresholdSeconds) {
  const cacheTimestamp = payload.cacheTimestamp;

  if (!Number.isInteger(cacheTimestamp) || cacheTimestamp <= 0) {
    return {
      status: 2,
      line: `CRITICAL: ${label} response from ${url} is missing a valid cacheTimestamp`,
    };
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
    return {
      status: 1,
      line: `WARNING: ${label} cacheTimestamp is in the future. refreshedAt=${refreshedAtHuman} (${refreshedAtIso}) age=${ageHuman}`,
      details: { label, ageHuman, refreshedAtHuman, refreshedAtIso, rateCount, providerDate },
    };
  }

  if (ageSeconds > thresholdSeconds) {
    return {
      status: 2,
      line: `CRITICAL: ${label} cache is stale. age=${ageHuman} threshold=${thresholdHuman} refreshedAt=${refreshedAtHuman} (${refreshedAtIso}) rateCount=${rateCount} providerMarker=${providerDate}`,
      details: { label, ageHuman, thresholdHuman, refreshedAtHuman, refreshedAtIso, rateCount, providerDate },
    };
  }

  return {
    status: 0,
    line: `OK: ${label} cache is fresh. age=${ageHuman} threshold=${thresholdHuman} refreshedAt=${refreshedAtHuman} (${refreshedAtIso}) rateCount=${rateCount} providerMarker=${providerDate}`,
    details: { label, ageHuman, thresholdHuman, refreshedAtHuman, refreshedAtIso, rateCount, providerDate },
  };
}

async function checkEndpoint(check, url, thresholdSeconds) {
  try {
    const response = await fetchJson(url);

    if (!response.ok) {
      const bodyPreview = response.text ? ` Response body: ${response.text.slice(0, 200)}` : "";
      return {
        status: 2,
        line: `CRITICAL: ${check.label} endpoint returned HTTP ${response.status} from ${url}.${bodyPreview}`.trim(),
      };
    }

    let payload;
    try {
      payload = JSON.parse(response.text);
    } catch (error) {
      return {
        status: 2,
        line: `CRITICAL: Unable to parse ${check.label} response from ${url}: ${error.message}`,
      };
    }

    return evaluatePayload(check.label, url, payload, thresholdSeconds);
  } catch (error) {
    return {
      status: 2,
      line: `CRITICAL: Failed to reach ${check.label} endpoint at ${url}: ${error.message}`,
    };
  }
}

function buildSlackPayload(results, overallStatus) {
  const statusLabel = overallStatus === 0 ? "OK" : overallStatus === 1 ? "WARNING" : "CRITICAL";
  const emoji = overallStatus === 0 ? ":white_check_mark:" : overallStatus === 1 ? ":warning:" : ":x:";
  const color = overallStatus === 0 ? "good" : overallStatus === 1 ? "warning" : "danger";
  const body = results.map((result) => result.line).join("\n");

  return {
    attachments: [
      {
        color,
        text: `${emoji} Wealth Map cache freshness check: ${statusLabel}\n${body}`,
      },
    ],
  };
}

async function postToSlack(webhookUrl, results, overallStatus) {
  const response = await fetch(webhookUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(buildSlackPayload(results, overallStatus)),
  });

  if (!response.ok) {
    throw new Error(`Slack webhook returned HTTP ${response.status}`);
  }
}

async function runCheck(argv = process.argv.slice(2), env = process.env) {
  let options;
  try {
    options = parseArgs(argv);
  } catch (error) {
    return {
      exitCode: 2,
      stdoutLines: [`CRITICAL: ${error.message}`, usage()],
      results: [],
    };
  }

  if (options.showHelp) {
    return {
      exitCode: 0,
      stdoutLines: [usage()],
      results: [],
    };
  }

  const results = [];
  let overallStatus = 0;

  for (const check of options.checks) {
    let url;

    try {
      url = resolveUrl(check, options.customUrl, env);
    } catch (error) {
      const line = `CRITICAL: ${error.message}`;
      results.push({ status: 2, line });
      overallStatus = 2;
      continue;
    }

    if (!url) {
      const line = `CRITICAL: Missing endpoint URL for ${check.label}`;
      results.push({ status: 2, line });
      overallStatus = 2;
      continue;
    }

    const result = await checkEndpoint(check, url, options.thresholdSeconds);
    results.push(result);
    overallStatus = Math.max(overallStatus, result.status);
  }

  if (env.SLACK_WEBHOOK_URL && overallStatus === 2) {
    try {
      await postToSlack(env.SLACK_WEBHOOK_URL, results, overallStatus);
    } catch (error) {
      results.push({
        status: 1,
        line: `WARNING: Failed to post cache freshness report to Slack webhook: ${error.message}`,
      });
      overallStatus = Math.max(overallStatus, 1);
    }
  }

  return {
    exitCode: overallStatus,
    stdoutLines: results.map((result) => result.line),
    results,
  };
}

async function main() {
  const report = await runCheck();
  for (const line of report.stdoutLines) {
    console.log(line);
  }
  process.exit(report.exitCode);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`CRITICAL: ${error.message}`);
    process.exit(2);
  });
}

module.exports = {
  runCheck,
};
