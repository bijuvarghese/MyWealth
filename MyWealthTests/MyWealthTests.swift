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
        let settings = AppSettings(userDefaults: defaults)

        #expect(settings.hasCompletedOnboarding == false)

        settings.completeOnboarding(
            baseCurrency: .eur,
            displayCurrencies: [.usd, .inr]
        )

        let restoredSettings = AppSettings(userDefaults: defaults)
        #expect(restoredSettings.hasCompletedOnboarding == true)
        #expect(restoredSettings.baseCurrency == .eur)
        #expect(restoredSettings.totalCurrencies == [.eur, .usd, .inr])
    }

    private func makeIsolatedDefaults() throws -> UserDefaults {
        let suiteName = "MyWealthTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

}
