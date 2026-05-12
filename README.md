# My Wealth

A modern SwiftUI iOS app for tracking personal finances, budgets, and insights.

## Overview

My Wealth is built with a clean SwiftUI-first approach, unidirectional data flow, and async/await concurrency. It provides a solid foundation for features like budgeting, expense tracking, and financial insights.

- Platform(s): iOS
- Minimum OS: iOS 17.0
- Xcode: 26.1+
- Swift: 5.10+

## Features

- SwiftUI interface with state driven updates
- Async/await networking and background tasks
- Dependency injection via protocols
- Swift Data (or Core Data) persistence-ready structure
- App Intents-ready hooks for future integrations (Shortcuts, Spotlight)
- Widgets and Live Activities scaffolding (optional)

## Exchange Rate Proxy

The app fetches USD to INR exchange rates through a Firebase HTTPS Cloud Function so the Apilayer API key is not shipped in the iOS app.

1. Install and sign in to the Firebase CLI.
2. From this directory, select the Firebase project:

   ```sh
   firebase use mywealth-api-router
   ```

3. Store the Apilayer key in Secret Manager:

   ```sh
   firebase functions:secrets:set EXCHANGE_RATES_API_KEY
   ```

4. Deploy the function:

   ```sh
   cd functions
   npm install
   cd ..
   firebase deploy --only functions
   ```

The iOS app reads `ExchangeRateProxyURL` from `MyWealth/Info.plist`, which is currently configured for the `mywealth-api-router` Firebase project.
