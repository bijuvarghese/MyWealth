//
//  AssetViewModel.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//

import SwiftUI
import SwiftData
import Charts

@Observable
final class DashboardViewModel: AssetOperations {

    private enum DefaultsKeys {
        static let lastUpdated = "exchangeRate.lastUpdated"
        static let rate = "exchangeRate.value"
        static let rates = "exchangeRate.rates"
    }

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let exchangeRateService: any ExchangeRateFetching

    var exchangeRate: Double = 0
    var exchangeRates: [String: Double] = ["USD": 1]
    var isLoadingRate = false
    var rateErrorMessage: String?
    var lastUpdated: Date? = nil
    var selectedAsset: Asset?

    init(
        autoRefreshRate: Bool = true,
        userDefaults: UserDefaults = .standard,
        exchangeRateService: any ExchangeRateFetching = FirebaseExchangeRateService.shared
    ) {
        self.userDefaults = userDefaults
        self.exchangeRateService = exchangeRateService

        if let savedRate = userDefaults.object(forKey: DefaultsKeys.rate) as? Double {
            self.exchangeRate = savedRate
        }
        if let savedRates = userDefaults.object(forKey: DefaultsKeys.rates) as? [String: Double] {
            self.exchangeRates = savedRates.merging(["USD": 1]) { current, _ in current }
        }
        if let savedDateInterval = userDefaults.object(forKey: DefaultsKeys.lastUpdated) as? TimeInterval {
            self.lastUpdated = Date(timeIntervalSince1970: savedDateInterval)
        }
        guard autoRefreshRate else {
            return
        }
        Task { [weak self] in
            await self?.refreshExchangeRateIfNeeded()
        }
    }
    
    @MainActor
    func refreshExchangeRateIfNeeded() async {
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)
        if let last = lastUpdated, last >= startOfToday {
            // Already refreshed sometime today
            return
        }
        await fetchExchangeRate()
    }
    
    func fetchExchangeRate() async {
        isLoadingRate = true
        defer { isLoadingRate = false }
        do {
            let decoded = try await exchangeRateService.fetchLatestExchangeRates()
            let rates = (decoded.rates ?? [:]).merging(["USD": 1]) { current, _ in current }
            guard let rate = rates["INR"] else {
                rateErrorMessage = "Exchange rates are missing INR. Totals may be incomplete."
                return
            }

            let now = Date()
            exchangeRates = rates
            exchangeRate = rate
            lastUpdated = now
            rateErrorMessage = nil
            persistRates(rates, inrRate: rate, at: now)
        } catch {
            rateErrorMessage = "Unable to refresh exchange rates. Showing the last saved rates."
            print("Warning: Error fetching rate:", error.localizedDescription)
        }
    }
    
    private func persistRates(_ rates: [String: Double], inrRate: Double, at date: Date) {
        userDefaults.set(inrRate, forKey: DefaultsKeys.rate)
        userDefaults.set(rates, forKey: DefaultsKeys.rates)
        userDefaults.set(date.timeIntervalSince1970, forKey: DefaultsKeys.lastUpdated)
    }
    
    func groupedByCategory(_ assets: [Asset]) -> [(Asset.CategoryType, Double)] {
        let dict = Dictionary(grouping: assets) { $0.displayCategory }
        return dict.map { (key, group) in
            let total = totalInUSD(group, exchangeRates: exchangeRates) ?? 0
            return (key, total)
        }.sorted { $0.1 > $1.1 }
    }
    
    func totalsByCurrency(_ assets: [Asset]) -> [CurrencyTotal] {
        totalsByCurrency(assets, currencies: uniqueCurrencies(assets.compactMap(\.currency)))
    }

    func totalsByCurrency(
        _ assets: [Asset],
        baseCurrency: Asset.CurrencyType,
        displayCurrencies: [Asset.CurrencyType]
    ) -> [CurrencyTotal] {
        totalsByCurrency(assets, currencies: uniqueCurrencies([baseCurrency] + displayCurrencies))
    }

    private func totalsByCurrency(_ assets: [Asset], currencies: [Asset.CurrencyType]) -> [CurrencyTotal] {
        currencies.compactMap { currency in
            guard let total = convertedTotal(assets, to: currency, exchangeRates: exchangeRates) else {
                return nil
            }
            return CurrencyTotal(currency: currency, amount: total)
        }
    }

    private func uniqueCurrencies(_ currencies: [Asset.CurrencyType]) -> [Asset.CurrencyType] {
        currencies.reduce(into: [Asset.CurrencyType]()) { result, currency in
            guard currency != .none, !result.contains(currency) else {
                return
            }
            result.append(currency)
        }
    }

    var rateStatus: RateStatusModel? {
        if isLoadingRate {
            return RateStatusModel(
                systemImage: "arrow.triangle.2.circlepath",
                message: "Refreshing exchange rates...",
                style: .loading
            )
        }

        if let rateErrorMessage {
            return RateStatusModel(
                systemImage: "exclamationmark.triangle",
                message: rateErrorMessage,
                style: .warning
            )
        }

        guard let lastUpdated else {
            return RateStatusModel(
                systemImage: "clock",
                message: "Exchange rates have not been refreshed yet.",
                style: .neutral
            )
        }

        if !Calendar.current.isDateInToday(lastUpdated) {
            return RateStatusModel(
                systemImage: "clock.badge.exclamationmark",
                message: "Exchange rates are from \(lastUpdated.formatted(date: .abbreviated, time: .shortened)).",
                style: .warning
            )
        }

        return nil
    }

    func transferRateRows(
        baseCurrency: Asset.CurrencyType,
        displayCurrencies: [Asset.CurrencyType]
    ) -> [TransferRateRow] {
        let targetCurrencies = uniqueCurrencies(displayCurrencies)
            .filter { $0 != baseCurrency }

        return targetCurrencies.map { targetCurrency in
            TransferRateRow(
                baseCurrency: baseCurrency,
                targetCurrency: targetCurrency,
                rate: transferRate(from: baseCurrency, to: targetCurrency)
            )
        }
    }

    func getFooterData(
        _ assets: [Asset],
        baseCurrency: Asset.CurrencyType,
        displayCurrencies: [Asset.CurrencyType]
    ) -> FooterModel {
        let orderedCurrencies = ([baseCurrency] + displayCurrencies).reduce(into: [Asset.CurrencyType]()) { result, currency in
            if !result.contains(currency) {
                result.append(currency)
            }
        }

        let totals = orderedCurrencies.compactMap { currency -> ConvertedCurrencyTotal? in
            guard let amount = convertedTotal(assets, to: currency, exchangeRates: exchangeRates) else {
                return nil
            }
            return ConvertedCurrencyTotal(currency: currency, amount: amount)
        }

        return FooterModel(
            totals: totals,
            baseCurrency: baseCurrency,
            lastUpdated: lastUpdated,
            rates: exchangeRates
        )
    }

    private func transferRate(
        from baseCurrency: Asset.CurrencyType,
        to targetCurrency: Asset.CurrencyType
    ) -> Double? {
        guard
            let baseRate = rate(for: baseCurrency),
            let targetRate = rate(for: targetCurrency),
            baseRate > 0
        else {
            return nil
        }

        return targetRate / baseRate
    }

    private func rate(for currency: Asset.CurrencyType) -> Double? {
        if currency == .usd {
            return 1
        }

        return exchangeRates[currency.rawValue]
    }
}

struct CurrencyTotal: Identifiable {
    let currency: Asset.CurrencyType
    let amount: Double

    var id: String { currency.rawValue }
}

struct ConvertedCurrencyTotal: Identifiable {
    let currency: Asset.CurrencyType
    let amount: Double

    var id: String { currency.rawValue }
}

struct TransferRateRow: Identifiable {
    let baseCurrency: Asset.CurrencyType
    let targetCurrency: Asset.CurrencyType
    let rate: Double?

    var id: String { "\(baseCurrency.rawValue)-\(targetCurrency.rawValue)" }
}

struct RateStatusModel: Identifiable {
    enum Style {
        case loading
        case neutral
        case warning
    }

    let systemImage: String
    let message: String
    let style: Style

    var id: String { "\(systemImage)-\(message)" }
}

struct RateResponse: Codable {
    let base, date: String?
    let rates: [String: Double]?
    let success: Bool?
    let timestamp: Int?
}
