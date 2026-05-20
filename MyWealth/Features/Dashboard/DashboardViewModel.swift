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

    var exchangeRate: Double = 0
    var exchangeRates: [String: Double] = ["USD": 1]
    var isLoadingRate = false
    var lastUpdated: Date? = nil
    var selectedAsset: Asset?

    init(autoRefreshRate: Bool = true) {
        if let savedRate = UserDefaults.standard.object(forKey: DefaultsKeys.rate) as? Double {
            self.exchangeRate = savedRate
        }
        if let savedRates = UserDefaults.standard.object(forKey: DefaultsKeys.rates) as? [String: Double] {
            self.exchangeRates = savedRates.merging(["USD": 1]) { current, _ in current }
        }
        if let savedDateInterval = UserDefaults.standard.object(forKey: DefaultsKeys.lastUpdated) as? TimeInterval {
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
            let decoded = try await FirebaseExchangeRateService.shared.fetchLatestExchangeRates()
            let rates = (decoded.rates ?? [:]).merging(["USD": 1]) { current, _ in current }
            guard let rate = rates["INR"] else { return }

            let now = Date()
            exchangeRates = rates
            exchangeRate = rate
            lastUpdated = now
            persistRates(rates, inrRate: rate, at: now)
        } catch {
            print("Warning: Error fetching rate:", error.localizedDescription)
        }
    }
    
    private func persistRates(_ rates: [String: Double], inrRate: Double, at date: Date) {
        UserDefaults.standard.set(inrRate, forKey: DefaultsKeys.rate)
        UserDefaults.standard.set(rates, forKey: DefaultsKeys.rates)
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: DefaultsKeys.lastUpdated)
    }
    
    func groupedByCategory(_ assets: [Asset]) -> [(Asset.CategoryType, Double)] {
        let dict = Dictionary(grouping: assets) { $0.category }
        return dict.map { (key, group) in
            let total = totalInUSD(group, exchangeRate: exchangeRate)
            return (key ?? .others, total)
        }.sorted { $0.1 > $1.1 }
    }
    
    func totalsByCurrency(_ assets: [Asset]) -> [CurrencyTotal] {
        let assetCurrencies = assets.reduce(into: [Asset.CurrencyType]()) { result, asset in
            guard let currency = asset.currency, !result.contains(currency) else {
                return
            }
            result.append(currency)
        }

        return assetCurrencies.compactMap { currency in
            guard let total = convertedTotal(assets, to: currency, exchangeRates: exchangeRates) else {
                return nil
            }
            return CurrencyTotal(currency: currency, amount: total)
        }
        .filter { $0.amount > 0 }
        .sorted { $0.currency.rawValue < $1.currency.rawValue }
    }

    func transferRateRows(
        baseCurrency: Asset.CurrencyType,
        displayCurrencies: [Asset.CurrencyType]
    ) -> [TransferRateRow] {
        let targetCurrencies = displayCurrencies.reduce(into: [Asset.CurrencyType]()) { result, currency in
            guard currency != .none, currency != baseCurrency, !result.contains(currency) else {
                return
            }
            result.append(currency)
        }

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

struct RateResponse: Codable {
    let base, date: String?
    let rates: [String: Double]?
    let success: Bool?
    let timestamp: Int?
}
