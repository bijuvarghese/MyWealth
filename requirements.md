# My Wealth - Requirements Document

Based on my analysis of the codebase, here's a comprehensive requirements document derived from the implemented features in the "My Wealth" iOS app. I've organized it into functional requirements (what the app does) and non-functional requirements (quality attributes), inferred from the code structure, data models, UI components, and integrations.

## Functional Requirements

### 1. Asset Management
- **FR1.1**: Users must be able to add new assets with the following mandatory fields:
  - Name (string, non-empty)
  - Amount (positive decimal number)
  - Currency (selection from: USD, INR)
  - Category (selection from: Stocks, Real Estate, Crypto, Bank Deposits, Mutual Funds, Others)
- **FR1.2**: Users must be able to edit existing assets, updating any of the fields listed in FR1.1
- **FR1.3**: Users must be able to delete existing assets
- **FR1.4**: Assets must automatically record a "last updated" timestamp when created or modified

### 2. Asset Display and Navigation
- **FR2.1**: The app must display a list of all assets when assets exist, showing:
  - Category icon (system image based on category type)
  - Asset name
  - Amount with currency code
  - Category name
- **FR2.2**: When no assets exist, the app must display an empty state with appropriate messaging and visual cues
- **FR2.3**: Tapping an asset in the list must open an edit form pre-populated with existing data
- **FR2.4**: Users must be able to delete assets directly from the list view

### 3. Financial Calculations and Currency Conversion
- **FR3.1**: The app must calculate and display total portfolio value in USD
- **FR3.2**: The app must calculate and display total portfolio value in INR
- **FR3.3**: Currency conversion must use real-time USD-INR exchange rates
- **FR3.4**: Exchange rates must be fetched from an external API (apilayer.com exchangerates_data)
- **FR3.5**: Exchange rates must be cached locally and refreshed daily (not more than once per day)
- **FR3.6**: Calculations must handle mixed currencies (convert INR assets to USD for totals, and vice versa)

### 4. Data Visualization
- **FR4.1**: The app must display a bar chart showing asset distribution by category in USD values
- **FR4.2**: The app must display a pie chart showing the proportion of USD vs INR-denominated assets
- **FR4.3**: Charts must only display when assets exist
- **FR4.4**: Charts must update automatically when asset data changes

### 5. Data Persistence
- **FR5.1**: All asset data must be persisted locally using SwiftData
- **FR5.2**: Exchange rate data must be cached in UserDefaults
- **FR5.3**: The app must handle data migration and schema changes gracefully

## Non-Functional Requirements

### 1. Performance
- **NFR1.1**: Exchange rate API calls must be asynchronous and not block the UI
- **NFR1.2**: Asset list rendering must be efficient for large numbers of assets
- **NFR1.3**: Calculations must be performed efficiently without noticeable delays

### 2. Usability
- **NFR2.1**: The interface must follow iOS design guidelines and use SwiftUI components
- **NFR2.2**: Form validation must prevent saving invalid data (empty names, non-numeric amounts)
- **NFR2.3**: Navigation must use standard iOS patterns (NavigationStack, sheets for modals)
- **NFR2.4**: Empty states must provide clear guidance on next steps

### 3. Reliability
- **NFR3.1**: Network failures must be handled gracefully with appropriate error logging
- **NFR3.2**: Invalid API responses must not crash the app
- **NFR3.3**: Data persistence failures must be handled with fatal error termination (as implemented)

### 4. Platform Requirements
- **NFR4.1**: Minimum iOS version: 17.0
- **NFR4.2**: Must support iPhone devices
- **NFR4.3**: Must use Swift 5.10+ and Xcode 15.1+

### 5. Architecture
- **NFR5.1**: Must follow MVVM pattern with Observable view models
- **NFR5.2**: Must use dependency injection via protocols (AssetOperations)
- **NFR5.3**: Must implement unidirectional data flow
- **NFR5.4**: Network layer must be reusable and generic

### 6. Security
- **NFR6.1**: API keys must be hardcoded in source code (current implementation - note: this is not production-ready)
- **NFR6.2**: User data must be stored securely using SwiftData encryption capabilities

### 7. Extensibility
- **NFR7.1**: Code must be structured for future features like budgeting, expense tracking, and financial insights
- **NFR7.2**: Must include scaffolding for App Intents, widgets, and Live Activities
- **NFR7.3**: Tab-based navigation must be prepared for additional views beyond the dashboard

## Assumptions and Constraints
- Users have internet access for exchange rate updates (app functions offline for calculations with cached rates)
- All monetary values are positive (no support for debts/liabilities)
- Only USD and INR currencies are supported
- Exchange rate API has a free tier with reasonable limits
- SwiftData is the persistence solution (not Core Data migration)

This requirements document captures the current scope of the implemented features. Additional features mentioned in the README (budgeting, expense tracking, widgets) are not yet implemented in the code.