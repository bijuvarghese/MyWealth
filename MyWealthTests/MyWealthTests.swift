//
//  MyWealthTests.swift
//  MyWealthTests
//
//  Created by Biju Varghese on 11/8/25.
//

import Testing
import Foundation
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
    }

    private func makeIsolatedDefaults() throws -> UserDefaults {
        let suiteName = "MyWealthTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
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
