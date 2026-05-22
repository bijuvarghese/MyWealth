const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const { Datastore } = require("@google-cloud/datastore");

const exchangeRatesApiKey = defineSecret("EXCHANGE_RATES_API_KEY");
const REGION = "us-central1";
const EXCHANGE_RATE_CACHE_KIND = "ExchangeRateCache";
const EXCHANGE_RATE_CACHE_NAME = "latest";
const EXCHANGE_RATE_BASE = "USD";
const CLIENT_CACHE_SECONDS = 300;
const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const MAX_REQUESTS_PER_WINDOW = 60;
const SUPPORTED_SYMBOLS = [
  "AED", "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN",
  "BAM", "BBD", "BDT", "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BRL",
  "BSD", "BTC", "BTN", "BWP", "BYN", "BYR", "BZD", "CAD", "CDF", "CHF",
  "CLF", "CLP", "CNH", "CNY", "COP", "CRC", "CUC", "CUP", "CVE", "CZK",
  "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", "ETB", "EUR", "FJD", "FKP",
  "GBP", "GEL", "GGP", "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD", "HKD",
  "HNL", "HRK", "HTG", "HUF", "IDR", "ILS", "IMP", "INR", "IQD", "IRR",
  "ISK", "JEP", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", "KMF", "KPW",
  "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LRD", "LSL", "LTL",
  "LVL", "LYD", "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP", "MRU",
  "MUR", "MVR", "MWK", "MXN", "MYR", "MZN", "NAD", "NGN", "NIO", "NOK",
  "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PKR", "PLN", "PYG",
  "QAR", "RON", "RSD", "RUB", "RWF", "SAR", "SBD", "SCR", "SDG", "SEK",
  "SGD", "SHP", "SLE", "SLL", "SOS", "SRD", "STD", "STN", "SVC", "SYP",
  "SZL", "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD", "TZS",
  "UAH", "UGX", "USD", "UYU", "UZS", "VES", "VND", "VUV", "WST", "XAF",
  "XAG", "XAU", "XCD", "XCG", "XDR", "XOF", "XPF", "YER", "ZAR", "ZMK",
  "ZMW", "ZWL",
];
const supportedSymbolSet = new Set(SUPPORTED_SYMBOLS);

const requestCountsByClient = new Map();
const datastore = new Datastore();

function pruneExpiredRequestCounts(now) {
  if (requestCountsByClient.size < 1000) {
    return;
  }

  for (const [identifier, current] of requestCountsByClient.entries()) {
    if (current.resetAt <= now) {
      requestCountsByClient.delete(identifier);
    }
  }
}

function clientIdentifier(request) {
  const forwardedFor = request.get("x-forwarded-for");
  if (forwardedFor) {
    return forwardedFor.split(",")[0].trim();
  }

  return request.ip || "unknown";
}

function isRateLimited(identifier, now) {
  pruneExpiredRequestCounts(now);

  const current = requestCountsByClient.get(identifier);

  if (!current || current.resetAt <= now) {
    requestCountsByClient.set(identifier, {
      count: 1,
      resetAt: now + RATE_LIMIT_WINDOW_MS,
    });
    return false;
  }

  current.count += 1;
  return current.count > MAX_REQUESTS_PER_WINDOW;
}

function sanitizeProviderError(payload) {
  return {
    code: payload?.error?.code ?? payload?.code ?? null,
    type: payload?.error?.type ?? payload?.type ?? null,
    success: payload?.success,
  };
}

function cacheKey() {
  return datastore.key([EXCHANGE_RATE_CACHE_KIND, EXCHANGE_RATE_CACHE_NAME]);
}

function cacheControlHeader(maxAgeSeconds = CLIENT_CACHE_SECONDS) {
  return `public, max-age=${maxAgeSeconds}, s-maxage=${maxAgeSeconds}`;
}

function validateExchangeRatePayload(payload) {
  return payload && typeof payload === "object" && typeof payload.rates === "object";
}

function normalizeExchangeRatePayload(payload) {
  const filteredRates = Object.fromEntries(
    Object.entries(payload.rates ?? {})
      .filter(([symbol, rate]) => supportedSymbolSet.has(symbol) && typeof rate === "number")
  );

  return {
    ...payload,
    base: payload.base ?? EXCHANGE_RATE_BASE,
    rates: {
      ...filteredRates,
      [EXCHANGE_RATE_BASE]: filteredRates[EXCHANGE_RATE_BASE] ?? 1,
    },
  };
}

async function fetchLatestExchangeRatePayload() {
  const apiKey = exchangeRatesApiKey.value();
  const url = new URL("https://api.apilayer.com/exchangerates_data/latest");
  url.searchParams.set("base", EXCHANGE_RATE_BASE);
  url.searchParams.set("symbols", SUPPORTED_SYMBOLS.join(","));

  const externalResponse = await fetch(url, {
    headers: {
      apikey: apiKey,
    },
  });
  const payload = await externalResponse.json();

  if (!externalResponse.ok || payload?.success === false || !validateExchangeRatePayload(payload)) {
    logger.error("Exchange rate API request failed", {
      status: externalResponse.status,
      providerError: sanitizeProviderError(payload),
    });
    throw new Error("Exchange rate provider request failed");
  }

  return normalizeExchangeRatePayload(payload);
}

async function writeExchangeRateCache(payload) {
  await datastore.save({
    key: cacheKey(),
    data: [
      {
        name: "payload",
        value: JSON.stringify(payload),
        excludeFromIndexes: true,
      },
      {
        name: "base",
        value: payload.base ?? EXCHANGE_RATE_BASE,
      },
      {
        name: "providerDate",
        value: payload.date ?? null,
      },
      {
        name: "providerTimestamp",
        value: payload.timestamp ?? null,
      },
      {
        name: "refreshedAt",
        value: new Date(),
      },
    ],
  });
}

async function readCachedExchangeRatePayload() {
  const [entity] = await datastore.get(cacheKey());
  if (!entity?.payload) {
    return null;
  }

  const payload = JSON.parse(entity.payload);
  return validateExchangeRatePayload(payload)
    ? normalizeExchangeRatePayload(payload)
    : null;
}

async function refreshCachedExchangeRates(reason) {
  const payload = await fetchLatestExchangeRatePayload();
  await writeExchangeRateCache(payload);
  logger.info("Exchange rate cache refreshed", {
    reason,
    base: payload.base ?? EXCHANGE_RATE_BASE,
    rateCount: Object.keys(payload.rates ?? {}).length,
    providerDate: payload.date ?? null,
  });
  return payload;
}

exports.refreshExchangeRateCache = onSchedule(
  {
    region: REGION,
    schedule: "0 0,8,16 * * *",
    timeZone: "Etc/UTC",
    secrets: [exchangeRatesApiKey],
    maxInstances: 1,
    timeoutSeconds: 30,
  },
  async () => {
    await refreshCachedExchangeRates("scheduled-refresh");
  }
);

exports.latestExchangeRate = onRequest(
  {
    region: REGION,
    secrets: [exchangeRatesApiKey],
    cors: false,
    maxInstances: 2,
    timeoutSeconds: 15,
  },
  async (request, response) => {
    response.set("X-Content-Type-Options", "nosniff");

    if (request.method !== "GET") {
      response.set("Allow", "GET");
      response.status(405).json({ success: false, error: "Method not allowed" });
      return;
    }

    const now = Date.now();
    const client = clientIdentifier(request);
    if (isRateLimited(client, now)) {
      response.set("Retry-After", String(RATE_LIMIT_WINDOW_MS / 1000));
      response.status(429).json({ success: false, error: "Too many requests" });
      return;
    }

    try {
      const cachedPayload = await readCachedExchangeRatePayload();
      if (cachedPayload) {
        response.set("Cache-Control", cacheControlHeader());
        response.status(200).json(cachedPayload);
        return;
      }

      const payload = await refreshCachedExchangeRates("cache-miss");
      response.set("Cache-Control", cacheControlHeader());
      response.status(200).json(payload);
    } catch (error) {
      logger.error("Unable to fetch exchange rate", {
        message: error instanceof Error ? error.message : String(error),
      });

      response.status(500).json({
        success: false,
        error: "Exchange rate cache is unavailable",
      });
    }
  }
);
