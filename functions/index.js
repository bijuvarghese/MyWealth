const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const exchangeRatesApiKey = defineSecret("EXCHANGE_RATES_API_KEY");

exports.latestExchangeRate = onRequest(
  {
    region: "us-central1",
    secrets: [exchangeRatesApiKey],
  },
  async (request, response) => {
    if (request.method !== "GET") {
      response.set("Allow", "GET");
      response.status(405).json({ success: false, error: "Method not allowed" });
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
          payload,
        });
        response.status(502).json({
          success: false,
          error: "Exchange rate provider request failed",
        });
        return;
      }

      response.set("Cache-Control", "public, max-age=3600, s-maxage=3600");
      response.status(200).json(payload);
    } catch (error) {
      logger.error("Unable to fetch exchange rate", error);
      response.status(500).json({
        success: false,
        error: "Unable to fetch exchange rate",
      });
    }
  }
);
