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

    @Test func defaultReminderPreferenceHasNoRecordedChoice() async throws {
        let preference = ReminderPreference()

        #expect(preference.isEnabled == false)
        #expect(preference.hasMadeChoice == false)
    }

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

}
