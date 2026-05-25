FROM node:22-slim

WORKDIR /app

COPY cloud-run/cache-check-service /app/cloud-run/cache-check-service
COPY scripts ./scripts
COPY MyWealth/Info.plist ./MyWealth/Info.plist

EXPOSE 8080

CMD ["node", "cloud-run/cache-check-service/server.js"]
