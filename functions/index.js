const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const exchangeRatesApiKey = defineSecret("EXCHANGE_RATES_API_KEY");
const CACHE_TTL_MS = 60 * 60 * 1000;
const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const MAX_REQUESTS_PER_WINDOW = 60;

let cachedPayload = null;
let cachedAt = 0;
const requestCountsByClient = new Map();

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

exports.latestExchangeRate = onRequest(
  {
    region: "us-central1",
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

    if (cachedPayload && now - cachedAt < CACHE_TTL_MS) {
      response.set("Cache-Control", "public, max-age=3600, s-maxage=3600");
      response.status(200).json(cachedPayload);
      return;
    }

    const apiKey = exchangeRatesApiKey.value();
    const url = new URL("https://api.apilayer.com/exchangerates_data/latest");
    url.searchParams.set("base", "USD");

    try {
      const externalResponse = await fetch(url, {
        headers: {
          apikey: apiKey,
        },
      });
      const payload = await externalResponse.json();

      if (!externalResponse.ok || payload?.success === false) {
        logger.error("Exchange rate API request failed", {
          status: externalResponse.status,
          providerError: sanitizeProviderError(payload),
        });

        if (cachedPayload) {
          response.set("Cache-Control", "public, max-age=300, s-maxage=300");
          response.status(200).json({
            ...cachedPayload,
            stale: true,
          });
          return;
        }

        response.status(502).json({
          success: false,
          error: "Exchange rate provider request failed",
        });
        return;
      }

      cachedPayload = payload;
      cachedAt = now;
      response.set("Cache-Control", "public, max-age=3600, s-maxage=3600");
      response.status(200).json(payload);
    } catch (error) {
      logger.error("Unable to fetch exchange rate", {
        message: error instanceof Error ? error.message : String(error),
      });

      if (cachedPayload) {
        response.set("Cache-Control", "public, max-age=300, s-maxage=300");
        response.status(200).json({
          ...cachedPayload,
          stale: true,
        });
        return;
      }

      response.status(500).json({
        success: false,
        error: "Unable to fetch exchange rate",
      });
    }
  }
);
