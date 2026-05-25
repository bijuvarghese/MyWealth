//
//  MyWealthTests.swift
//  MyWealthTests
//
//  Created by Biju Varghese on 11/8/25.
//

import Testing
import Foundation
import SwiftData
@testable import MyWealth

struct MyWealthTests {

    @MainActor
    @Test func assetCurrencyTotalsConvertEveryAssetIntoEachCurrency() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5
        ]

        let assets = [
            Asset(name: "Cash", amount: 1, currency: .usd, category: .bank),
            Asset(name: "Euro Cash", amount: 2, currency: .eur, category: .bank)
        ]

        let totals = viewModel.totalsByCurrency(assets)
        let usdTotal = try #require(totals.first { $0.currency == .usd })
        let eurTotal = try #require(totals.first { $0.currency == .eur })

        #expect(usdTotal.amount == 5)
        #expect(eurTotal.amount == 2.5)
    }

    @MainActor
    @Test func configuredCurrencyTotalsUseBaseAndDisplayCurrencies() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5,
            "INR": 80
        ]

        let assets = [
            Asset(name: "Cash", amount: 1, currency: .usd, category: .bank),
            Asset(name: "Euro Cash", amount: 2, currency: .eur, category: .bank)
        ]

        let totals = viewModel.totalsByCurrency(
            assets,
            baseCurrency: .inr,
            displayCurrencies: [.usd, .eur]
        )

        #expect(totals.map(\.currency) == [.inr, .usd, .eur])
        #expect(totals.first { $0.currency == .inr }?.amount == 400)
        #expect(totals.first { $0.currency == .usd }?.amount == 5)
        #expect(totals.first { $0.currency == .eur }?.amount == 2.5)
    }

    @MainActor
    @Test func configuredCurrencyTotalsSubtractLiabilitiesForNetWorth() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5,
            "INR": 80
        ]

        let assets = [
            Asset(name: "Cash", amount: 1_000, currency: .usd, category: .bank),
            Asset(name: "Euro Cash", amount: 500, currency: .eur, category: .bank)
        ]
        let liabilities = [
            Liability(name: "Mortgage", amount: 200, currency: .usd, category: .mortgage)
        ]

        let totals = viewModel.totalsByCurrency(
            assets,
            liabilities: liabilities,
            baseCurrency: .usd,
            displayCurrencies: [.eur, .inr]
        )

        #expect(totals.first { $0.currency == .usd }?.amount == 1_800)
        #expect(totals.first { $0.currency == .eur }?.amount == 900)
        #expect(totals.first { $0.currency == .inr }?.amount == 144_000)
    }

    @MainActor
    @Test func portfolioInsightsDescribeAllocationAndDebt() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let assets = [
            Asset(name: "House", amount: 700, currency: .usd, category: .realEstate),
            Asset(name: "Cash", amount: 300, currency: .usd, category: .bank)
        ]
        let liabilities = [
            Liability(name: "Mortgage", amount: 250, currency: .usd, category: .mortgage)
        ]

        let rows = viewModel.portfolioInsightRows(
            assets: assets,
            liabilities: liabilities,
            netWorthSnapshots: [],
            baseCurrency: .usd
        )

        #expect(rows.map(\.message).contains("70% of your assets are in Real Estate."))
        #expect(rows.map(\.message).contains("Cash and bank deposits make up 30% of your assets."))
        #expect(rows.map(\.message).contains("Liabilities are 25% of your asset value."))
    }

    @MainActor
    @Test func portfolioInsightsDescribeNetWorthTrend() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let now = Date()
        let snapshots = [
            NetWorthSnapshot(amount: 1_000, currencyCode: "USD", recordedAt: now),
            NetWorthSnapshot(amount: 1_250, currencyCode: "USD", recordedAt: now.addingTimeInterval(60))
        ]

        let rows = viewModel.portfolioInsightRows(
            assets: [],
            liabilities: [],
            netWorthSnapshots: snapshots,
            baseCurrency: .usd
        )

        #expect(rows.first?.message == "Net worth increased by $250.00 since the last snapshot.")
    }

    @MainActor
    @Test func onboardingCompletionPersistsSelectedCurrencies() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )

        #expect(settings.hasCompletedOnboarding.isComplete == false)
        #expect(settings.hasCompletedOnboarding.missingSteps == [.baseCurrency, .displayCurrencies])

        settings.completeOnboarding(
            baseCurrency: .eur,
            displayCurrencies: [.usd, .inr]
        )

        let restoredSettings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )
        #expect(restoredSettings.hasCompletedOnboarding.isComplete == true)
        #expect(restoredSettings.hasCompletedOnboarding.missingSteps.isEmpty)
        #expect(restoredSettings.baseCurrency == .eur)
        #expect(restoredSettings.totalCurrencies == [.eur, .usd, .inr])
    }

    @MainActor
    @Test func displayCurrencyOrderCanBeRearrangedAndPersisted() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )

        settings.completeOnboarding(
            baseCurrency: .usd,
            displayCurrencies: [.eur, .inr, .gbp]
        )

        settings.moveTotalCurrencies(fromOffsets: IndexSet(integer: 3), toOffset: 1)

        let restoredSettings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )

        #expect(settings.totalCurrencies == [.usd, .gbp, .eur, .inr])
        #expect(restoredSettings.totalCurrencies == [.usd, .gbp, .eur, .inr])
    }

    @MainActor
    @Test func displayCurrencyTogglePreservesPriorityOrderAndBaseCurrency() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { true }
        )

        settings.toggleTotalCurrency(.eur)
        settings.toggleTotalCurrency(.usd)

        #expect(settings.totalCurrencies == [.usd, .inr, .eur])
    }

    @MainActor
    @Test func transferRateRowsConvertFromBaseCurrencyToDisplayCurrencies() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5,
            "INR": 80
        ]

        let rows = viewModel.transferRateRows(
            baseCurrency: .eur,
            displayCurrencies: [.eur, .usd, .inr]
        )

        #expect(rows.count == 2)
        #expect(rows.map(\.targetCurrency) == [.usd, .inr])
        #expect(rows.first { $0.targetCurrency == .usd }?.rate == 2)
        #expect(rows.first { $0.targetCurrency == .inr }?.rate == 160)
    }

    @MainActor
    @Test func transferRateRowsCanBeLimitedForDashboard() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5,
            "INR": 80,
            "GBP": 0.8,
            "CAD": 1.3
        ]

        let rows = viewModel.transferRateRows(
            baseCurrency: .usd,
            displayCurrencies: [.usd, .eur, .inr, .gbp, .cad],
            limit: 3
        )

        #expect(rows.map(\.targetCurrency) == [.eur, .inr, .gbp])
    }

    @MainActor
    @Test func rateStatusShowsMissingRefreshAndErrors() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)

        #expect(viewModel.rateStatus?.message == "Exchange rates have not been refreshed yet.")

        viewModel.rateErrorMessage = "Unable to refresh exchange rates. Showing the last saved rates."

        #expect(viewModel.rateStatus?.message == "Unable to refresh exchange rates. Showing the last saved rates.")
    }

    @MainActor
    @Test func dashboardViewModelFetchUsesInjectedServiceAndDefaults() async throws {
        let defaults = try makeIsolatedDefaults()
        let service = StubExchangeRateService(
            response: RateResponse(
                base: "USD",
                date: "2026-05-20",
                rates: ["EUR": 0.5, "INR": 80],
                success: true,
                timestamp: 1_779_264_000
            )
        )
        let viewModel = DashboardViewModel(
            autoRefreshRate: false,
            userDefaults: defaults,
            exchangeRateService: service
        )

        await viewModel.fetchExchangeRate()

        let restoredViewModel = DashboardViewModel(
            autoRefreshRate: false,
            userDefaults: defaults,
            exchangeRateService: service
        )

        #expect(viewModel.exchangeRate == 80)
        #expect(viewModel.exchangeRates["USD"] == 1)
        #expect(viewModel.exchangeRates["EUR"] == 0.5)
        #expect(restoredViewModel.exchangeRate == 80)
        #expect(restoredViewModel.exchangeRates["INR"] == 80)
        #expect(viewModel.rateErrorMessage == nil)
    }

    @MainActor
    @Test func exchangeRateFetchDoesNotRequireINRUnlessNeeded() async throws {
        let defaults = try makeIsolatedDefaults()
        let service = StubExchangeRateService(
            response: RateResponse(
                base: "USD",
                date: "2026-05-20",
                rates: ["EUR": 0.5],
                success: true,
                timestamp: 1_779_264_000
            )
        )
        let viewModel = DashboardViewModel(
            autoRefreshRate: false,
            userDefaults: defaults,
            exchangeRateService: service
        )

        await viewModel.fetchExchangeRate(requiredCurrencies: [.eur])

        #expect(viewModel.exchangeRates["USD"] == 1)
        #expect(viewModel.exchangeRates["EUR"] == 0.5)
        #expect(viewModel.rateErrorMessage == nil)
        #expect(defaults.object(forKey: "exchangeRate.rates") as? [String: Double] == ["EUR": 0.5, "USD": 1])
    }

    @MainActor
    @Test func exchangeRateFetchWarnsOnlyForMissingRequiredCurrencies() async throws {
        let defaults = try makeIsolatedDefaults()
        let service = StubExchangeRateService(
            response: RateResponse(
                base: "USD",
                date: "2026-05-20",
                rates: ["EUR": 0.5],
                success: true,
                timestamp: 1_779_264_000
            )
        )
        let viewModel = DashboardViewModel(
            autoRefreshRate: false,
            userDefaults: defaults,
            exchangeRateService: service
        )

        await viewModel.fetchExchangeRate(requiredCurrencies: [.eur, .inr])

        #expect(viewModel.exchangeRates["EUR"] == 0.5)
        #expect(viewModel.rateErrorMessage == "Exchange rates are missing INR. Totals may be incomplete.")
    }

    @MainActor
    @Test func categoryAllocationRowsCalculatePercentages() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5
        ]

        let assets = [
            Asset(name: "Cash", amount: 100, currency: .usd, category: .bank),
            Asset(name: "Stocks", amount: 100, currency: .eur, category: .stocks)
        ]

        let rows = viewModel.categoryAllocationRows(assets)
        let stocks = try #require(rows.first { $0.category == .stocks })
        let bank = try #require(rows.first { $0.category == .bank })

        #expect(stocks.amount == 200)
        #expect(stocks.percentage == 2.0 / 3.0)
        #expect(bank.amount == 100)
        #expect(bank.percentage == 1.0 / 3.0)
    }

    @MainActor
    @Test func categoryAllocationRowsCanUseSelectedCurrency() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = [
            "USD": 1,
            "EUR": 0.5,
            "INR": 80
        ]

        let assets = [
            Asset(name: "Cash", amount: 100, currency: .usd, category: .bank),
            Asset(name: "Stocks", amount: 100, currency: .eur, category: .stocks)
        ]

        let rows = viewModel.categoryAllocationRows(assets, targetCurrency: .inr)
        let stocks = try #require(rows.first { $0.category == .stocks })
        let bank = try #require(rows.first { $0.category == .bank })

        #expect(stocks.amount == 16_000)
        #expect(stocks.percentage == 2.0 / 3.0)
        #expect(bank.amount == 8_000)
        #expect(bank.percentage == 1.0 / 3.0)
    }

    @MainActor
    @Test func netWorthTrendRowsSortFilterAndLimitSnapshots() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let now = Date()
        let snapshots = [
            NetWorthSnapshot(amount: 1, currencyCode: "EUR", recordedAt: now),
            NetWorthSnapshot(amount: 3, currencyCode: "USD", recordedAt: now.addingTimeInterval(30)),
            NetWorthSnapshot(amount: 1, currencyCode: "USD", recordedAt: now.addingTimeInterval(10)),
            NetWorthSnapshot(amount: 2, currencyCode: "USD", recordedAt: now.addingTimeInterval(20))
        ]

        let rows = viewModel.netWorthTrendRows(snapshots, baseCurrency: .usd, limit: 2)

        #expect(rows.map(\.amount) == [2, 3])
        #expect(rows.allSatisfy { $0.currencyCode == "USD" })
    }

    @MainActor
    @Test func netWorthTrendRowsUseStableUniqueSnapshotIds() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let context = try makeInMemoryModelContext()
        let now = Date()
        let snapshots = [
            NetWorthSnapshot(amount: 100, currencyCode: "USD", recordedAt: now),
            NetWorthSnapshot(amount: 200, currencyCode: "USD", recordedAt: now)
        ]
        snapshots.forEach { context.insert($0) }

        let rows = viewModel.netWorthTrendRows(snapshots, baseCurrency: .usd)

        #expect(Set(rows.map(\.id)).count == rows.count)
    }

    @MainActor
    @Test func recentAssetHistoryRowsUseLatestSnapshotsFirst() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let now = Date()
        let snapshots = [
            AssetValueSnapshot(
                assetIdentifier: "1",
                assetName: "Old",
                amount: 1,
                currencyCode: "USD",
                categoryName: "Bank Deposits",
                recordedAt: now
            ),
            AssetValueSnapshot(
                assetIdentifier: "2",
                assetName: "New",
                amount: 2,
                currencyCode: "EUR",
                categoryName: "Stocks",
                recordedAt: now.addingTimeInterval(60)
            )
        ]

        let rows = viewModel.recentAssetHistoryRows(snapshots, limit: 1)

        #expect(rows.map(\.assetName) == ["New"])
        #expect(rows.first?.currencyCode == "EUR")
    }

    @MainActor
    @Test func recentAssetHistoryRowsUseStableUniqueSnapshotIds() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let context = try makeInMemoryModelContext()
        let now = Date()
        let snapshots = [
            AssetValueSnapshot(
                assetIdentifier: "asset-1",
                assetName: "Cash",
                amount: 100,
                currencyCode: "USD",
                categoryName: "Bank Deposits",
                recordedAt: now
            ),
            AssetValueSnapshot(
                assetIdentifier: "asset-2",
                assetName: "Cash",
                amount: 100,
                currencyCode: "USD",
                categoryName: "Bank Deposits",
                recordedAt: now
            )
        ]
        snapshots.forEach { context.insert($0) }

        let rows = viewModel.recentAssetHistoryRows(snapshots)

        #expect(Set(rows.map(\.id)).count == rows.count)
    }

    @MainActor
    @Test func assetHistoryRowsFilterToSelectedAssetNewestFirst() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let asset = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        let otherAsset = Asset(name: "Stocks", amount: 250, currency: .usd, category: .stocks)
        let now = Date()
        let snapshots = [
            AssetValueSnapshot(
                assetIdentifier: asset.stableHistoryIdentifier,
                assetName: "Cash",
                amount: 90,
                currencyCode: "USD",
                categoryName: "Bank Deposits",
                recordedAt: now
            ),
            AssetValueSnapshot(
                assetIdentifier: otherAsset.stableHistoryIdentifier,
                assetName: "Stocks",
                amount: 250,
                currencyCode: "USD",
                categoryName: "Stocks",
                recordedAt: now.addingTimeInterval(30)
            ),
            AssetValueSnapshot(
                assetIdentifier: asset.stableHistoryIdentifier,
                assetName: "Cash",
                amount: 100,
                currencyCode: "USD",
                categoryName: "Bank Deposits",
                recordedAt: now.addingTimeInterval(60)
            )
        ]

        let rows = viewModel.assetHistoryRows(for: asset, snapshots: snapshots)

        #expect(rows.map(\.amount) == [100, 90])
        #expect(rows.allSatisfy { $0.assetName == "Cash" })
    }

    @MainActor
    @Test func assetHistoryRowsIncludeLegacyPersistentModelIdentifier() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        let context = try makeInMemoryModelContext()
        let asset = Asset(name: "Legacy", amount: 100, currency: .usd, category: .bank)
        context.insert(asset)
        let legacySnapshot = AssetValueSnapshot(
            assetIdentifier: String(describing: asset.persistentModelID),
            assetName: "Legacy",
            amount: 80,
            currencyCode: "USD",
            categoryName: "Bank Deposits"
        )

        let rows = viewModel.assetHistoryRows(for: asset, snapshots: [legacySnapshot])

        #expect(rows.map(\.amount) == [80])
    }

    @MainActor
    @Test func assetSnapshotRecordingIgnoresMetadataChanges() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1, "EUR": 0.5]
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        modelContext.insert(asset)
        let existingSnapshot = AssetValueSnapshot(
            assetIdentifier: String(describing: asset.persistentModelID),
            assetName: "Old Cash",
            amount: 100,
            currencyCode: "EUR",
            categoryName: "Stocks"
        )
        modelContext.insert(existingSnapshot)

        viewModel.recordPortfolioHistory(
            assets: [asset],
            baseCurrency: .usd,
            netWorthSnapshots: [],
            assetValueSnapshots: [existingSnapshot],
            modelContext: modelContext
        )

        let snapshots = try modelContext.fetch(FetchDescriptor<AssetValueSnapshot>())
        #expect(snapshots.count == 1)
    }

    @MainActor
    @Test func assetSnapshotRecordingUsesValueChanges() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        modelContext.insert(asset)
        let existingSnapshot = AssetValueSnapshot(
            assetIdentifier: String(describing: asset.persistentModelID),
            assetName: "Cash",
            amount: 90,
            currencyCode: "USD",
            categoryName: "Bank Deposits"
        )
        modelContext.insert(existingSnapshot)

        viewModel.recordPortfolioHistory(
            assets: [asset],
            baseCurrency: .usd,
            netWorthSnapshots: [],
            assetValueSnapshots: [existingSnapshot],
            modelContext: modelContext
        )

        let snapshots = try modelContext.fetch(FetchDescriptor<AssetValueSnapshot>())
        #expect(snapshots.count == 2)
    }

    @MainActor
    @Test func assetSnapshotRecordingUsesStableAssetIdentifier() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(name: "Cash", amount: 100, currency: .usd, category: .bank)
        modelContext.insert(asset)

        viewModel.recordPortfolioHistory(
            assets: [asset],
            baseCurrency: .usd,
            netWorthSnapshots: [],
            assetValueSnapshots: [],
            modelContext: modelContext
        )

        let snapshots = try modelContext.fetch(FetchDescriptor<AssetValueSnapshot>())
        let snapshot = try #require(snapshots.first)
        #expect(snapshot.assetIdentifier == asset.stableHistoryIdentifier)
        #expect(snapshot.assetIdentifier != String(describing: asset.persistentModelID))
    }

    @MainActor
    @Test func netWorthSnapshotRecordingSubtractsLiabilities() async throws {
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = ["USD": 1]
        let modelContext = try makeInMemoryModelContext()
        let asset = Asset(name: "Cash", amount: 1_000, currency: .usd, category: .bank)
        let liability = Liability(name: "Credit Card", amount: 250, currency: .usd, category: .creditCard)
        modelContext.insert(asset)
        modelContext.insert(liability)

        viewModel.recordPortfolioHistory(
            assets: [asset],
            liabilities: [liability],
            baseCurrency: .usd,
            netWorthSnapshots: [],
            assetValueSnapshots: [],
            modelContext: modelContext
        )

        let snapshots = try modelContext.fetch(FetchDescriptor<NetWorthSnapshot>())
        let snapshot = try #require(snapshots.first)
        #expect(snapshot.displayAmount == 750)
    }

    @MainActor
    @Test func onboardingCompletionRequiresReminderChoice() async throws {
        let defaults = try makeIsolatedDefaults()
        let settings = AppSettings(
            userDefaults: defaults,
            hasMadeReminderChoice: { false }
        )

        settings.completeOnboarding(
            baseCurrency: .eur,
            displayCurrencies: [.usd, .inr]
        )

        #expect(settings.hasCompletedOnboarding.isComplete == false)
        #expect(settings.hasCompletedOnboarding.missingSteps == [.reminders])
        #expect(settings.firstMissingOnboardingStep() == .reminders)
    }

    @MainActor
    @Test func defaultReminderPreferenceHasNoRecordedChoice() async throws {
        let preference = ReminderPreference()

        #expect(preference.isEnabled == false)
        #expect(preference.hasMadeChoice == false)
    }

    @MainActor
    @Test func legacyReminderPreferenceDecodesAsRecordedChoice() async throws {
        let legacyPreference = LegacyReminderPreference(
            isEnabled: false,
            frequency: .weekly,
            reminderTime: ReminderPreference.defaultReminderTime(),
            reminderType: .reviewPortfolio,
            lastReminderDate: nil
        )

        let data = try JSONEncoder().encode(legacyPreference)
        let preference = try JSONDecoder().decode(ReminderPreference.self, from: data)

        #expect(preference.hasMadeChoice == true)
        #expect(ReminderWeekday.allCases.contains(preference.weekday))
        #expect((1...ReminderPreference.maximumMonthlyReminderDay).contains(preference.monthDay))
    }

    @MainActor
    @Test func reminderPreferencePersistsWeeklyAlertDay() async throws {
        let preference = ReminderPreference(
            isEnabled: true,
            hasMadeChoice: true,
            frequency: .weekly,
            weekday: .friday,
            reminderTime: ReminderPreference.defaultReminderTime(),
            reminderType: .reviewPortfolio,
            lastReminderDate: nil
        )

        let data = try JSONEncoder().encode(preference)
        let restoredPreference = try JSONDecoder().decode(ReminderPreference.self, from: data)

        #expect(restoredPreference.weekday == .friday)
    }

    @MainActor
    @Test func reminderPreferencePersistsMonthlyAlertDay() async throws {
        let preference = ReminderPreference(
            isEnabled: true,
            hasMadeChoice: true,
            frequency: .monthly,
            monthDay: 15,
            reminderTime: ReminderPreference.defaultReminderTime(),
            reminderType: .reviewPortfolio,
            lastReminderDate: nil
        )

        let data = try JSONEncoder().encode(preference)
        let restoredPreference = try JSONDecoder().decode(ReminderPreference.self, from: data)

        #expect(restoredPreference.monthDay == 15)
    }

    @MainActor
    @Test func reminderPreferenceNormalizesMonthlyAlertDay() async throws {
        let earlyPreference = ReminderPreference(monthDay: 0)
        let latePreference = ReminderPreference(monthDay: 40)

        #expect(earlyPreference.monthDay == 1)
        #expect(latePreference.monthDay == ReminderPreference.maximumMonthlyReminderDay)
    }

    private func makeIsolatedDefaults() throws -> UserDefaults {
        let suiteName = "MyWealthTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @MainActor
    private func makeInMemoryModelContext() throws -> ModelContext {
        let schema = Schema([
            Asset.self,
            Liability.self,
            AssetValueSnapshot.self,
            NetWorthSnapshot.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private struct LegacyReminderPreference: Codable {
        var isEnabled: Bool
        var frequency: ReminderFrequency
        var reminderTime: Date
        var reminderType: ReminderType
        var lastReminderDate: Date?
    }

    private struct StubExchangeRateService: ExchangeRateFetching {
        let response: RateResponse

        func fetchLatestExchangeRates() async throws -> RateResponse {
            response
        }
    }

}
