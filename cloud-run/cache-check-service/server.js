"use strict";

const http = require("http");
const { runCheck } = require("../../scripts/check-cache-freshness");

const PORT = Number.parseInt(process.env.PORT ?? "8080", 10);
const RUN_CHECK_TOKEN = process.env.RUN_CHECK_TOKEN ?? "";

function writeJson(response, statusCode, payload) {
  response.writeHead(statusCode, { "Content-Type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(payload, null, 2));
}

function isAuthorized(request) {
  if (!RUN_CHECK_TOKEN) {
    return true;
  }

  const authorization = request.headers.authorization ?? "";
  return authorization === `Bearer ${RUN_CHECK_TOKEN}`;
}

function readBody(request) {
  return new Promise((resolve, reject) => {
    let body = "";

    request.setEncoding("utf8");
    request.on("data", (chunk) => {
      body += chunk;
      if (body.length > 1_000_000) {
        reject(new Error("Request body too large"));
      }
    });
    request.on("end", () => resolve(body));
    request.on("error", reject);
  });
}

function parseRequestOptions(bodyText) {
  if (!bodyText.trim()) {
    return { thresholdHours: null, only: null, slack: true };
  }

  const payload = JSON.parse(bodyText);
  const thresholdHours = payload.thresholdHours ?? null;
  const only = payload.only ?? null;
  const slack = payload.slack ?? true;

  if (thresholdHours !== null && (typeof thresholdHours !== "number" || Number.isNaN(thresholdHours))) {
    throw new Error("thresholdHours must be a number");
  }

  if (only !== null && !["exchange", "metal"].includes(only)) {
    throw new Error("only must be 'exchange' or 'metal'");
  }

  if (typeof slack !== "boolean") {
    throw new Error("slack must be a boolean");
  }

  return { thresholdHours, only, slack };
}

function buildArgs(options) {
  const args = [];

  if (options.only === "exchange") {
    args.push("--exchange-only");
  } else if (options.only === "metal") {
    args.push("--metal-only");
  }

  if (options.thresholdHours !== null) {
    args.push("--threshold-hours", String(options.thresholdHours));
  }

  return args;
}

function buildEnv(options) {
  const nextEnv = { ...process.env };

  if (!options.slack) {
    delete nextEnv.SLACK_WEBHOOK_URL;
  }

  return nextEnv;
}

function createServer() {
  return http.createServer(async (request, response) => {
    if (request.method === "GET" && request.url === "/healthz") {
      writeJson(response, 200, {
        ok: true,
        service: "cache-check-service",
        date: new Date().toISOString(),
      });
      return;
    }

    if (request.method === "POST" && request.url === "/run") {
      if (!isAuthorized(request)) {
        writeJson(response, 401, {
          ok: false,
          error: "Unauthorized",
        });
        return;
      }

      try {
        const bodyText = await readBody(request);
        const options = parseRequestOptions(bodyText);
        const report = await runCheck(buildArgs(options), buildEnv(options));

        writeJson(response, report.exitCode === 0 ? 200 : 503, {
          ok: report.exitCode === 0,
          exitCode: report.exitCode,
          lines: report.stdoutLines,
          checkedAt: new Date().toISOString(),
        });
      } catch (error) {
        writeJson(response, 400, {
          ok: false,
          error: error.message,
        });
      }
      return;
    }

    writeJson(response, 404, {
      ok: false,
      error: "Not found",
    });
  });
}

if (require.main === module) {
  const server = createServer();
  server.listen(PORT, () => {
    console.log(`cache-check-service listening on port ${PORT}`);
  });
}

module.exports = {
  createServer,
};
