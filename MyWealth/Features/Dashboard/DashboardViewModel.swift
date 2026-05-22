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
    func refreshExchangeRateIfNeeded(requiredCurrencies: [Asset.CurrencyType] = []) async {
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)
        let hasRequiredRates = missingRequiredRateCodes(
            in: exchangeRates,
            requiredCurrencies: requiredCurrencies
        ).isEmpty

        if let last = lastUpdated, last >= startOfToday, hasRequiredRates {
            // Already refreshed sometime today
            return
        }
        await fetchExchangeRate(requiredCurrencies: requiredCurrencies)
    }
    
    func fetchExchangeRate(requiredCurrencies: [Asset.CurrencyType] = []) async {
        isLoadingRate = true
        defer { isLoadingRate = false }
        do {
            let decoded = try await exchangeRateService.fetchLatestExchangeRates()
            let rates = (decoded.rates ?? [:]).merging(["USD": 1]) { current, _ in current }
            let missingRateCodes = missingRequiredRateCodes(
                in: rates,
                requiredCurrencies: requiredCurrencies
            )

            let now = Date()
            exchangeRates = rates
            exchangeRate = rates["INR"] ?? exchangeRate
            lastUpdated = now
            rateErrorMessage = missingRateCodes.isEmpty
                ? nil
                : "Exchange rates are missing \(missingRateCodes.joined(separator: ", ")). Totals may be incomplete."
            persistRates(rates, inrRate: exchangeRate, at: now)
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
        groupedByCategory(assets, targetCurrency: .usd)
    }

    func groupedByCategory(
        _ assets: [Asset],
        targetCurrency: Asset.CurrencyType
    ) -> [(Asset.CategoryType, Double)] {
        let dict = Dictionary(grouping: assets) { $0.displayCategory }
        return dict.map { (key, group) in
            let total = convertedTotal(group, to: targetCurrency, exchangeRates: exchangeRates) ?? 0
            return (key, total)
        }.sorted { $0.1 > $1.1 }
    }

    func categoryAllocationRows(_ assets: [Asset]) -> [CategoryAllocationRow] {
        categoryAllocationRows(assets, targetCurrency: .usd)
    }

    func categoryAllocationRows(
        _ assets: [Asset],
        targetCurrency: Asset.CurrencyType
    ) -> [CategoryAllocationRow] {
        let totals = groupedByCategory(assets, targetCurrency: targetCurrency)
        let portfolioTotal = totals.reduce(0) { $0 + $1.1 }
        guard portfolioTotal > 0 else {
            return []
        }

        return totals.map { category, amount in
            CategoryAllocationRow(
                category: category,
                amount: amount,
                percentage: amount / portfolioTotal
            )
        }
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

    func totalsByCurrency(
        _ assets: [Asset],
        liabilities: [Liability],
        baseCurrency: Asset.CurrencyType,
        displayCurrencies: [Asset.CurrencyType]
    ) -> [CurrencyTotal] {
        totalsByCurrency(
            assets,
            liabilities: liabilities,
            currencies: uniqueCurrencies([baseCurrency] + displayCurrencies)
        )
    }

    private func totalsByCurrency(_ assets: [Asset], currencies: [Asset.CurrencyType]) -> [CurrencyTotal] {
        currencies.compactMap { currency in
            guard let total = convertedTotal(assets, to: currency, exchangeRates: exchangeRates) else {
                return nil
            }
            return CurrencyTotal(currency: currency, amount: total)
        }
    }

    private func totalsByCurrency(
        _ assets: [Asset],
        liabilities: [Liability],
        currencies: [Asset.CurrencyType]
    ) -> [CurrencyTotal] {
        currencies.compactMap { currency in
            guard let total = netWorthTotal(
                assets,
                liabilities: liabilities,
                to: currency,
                exchangeRates: exchangeRates
            ) else {
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

    private func missingRequiredRateCodes(
        in rates: [String: Double],
        requiredCurrencies: [Asset.CurrencyType]
    ) -> [String] {
        uniqueCurrencies(requiredCurrencies)
            .filter { $0 != .usd }
            .map(\.rawValue)
            .filter { code in
                guard let rate = rates[code] else {
                    return true
                }
                return rate <= 0
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
        displayCurrencies: [Asset.CurrencyType],
        limit: Int? = nil
    ) -> [TransferRateRow] {
        var targetCurrencies = uniqueCurrencies(displayCurrencies)
            .filter { $0 != baseCurrency }

        if let limit {
            targetCurrencies = Array(targetCurrencies.prefix(limit))
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
        liabilities: [Liability] = [],
        baseCurrency: Asset.CurrencyType,
        displayCurrencies: [Asset.CurrencyType]
    ) -> FooterModel {
        let orderedCurrencies = ([baseCurrency] + displayCurrencies).reduce(into: [Asset.CurrencyType]()) { result, currency in
            if !result.contains(currency) {
                result.append(currency)
            }
        }

        let totals = orderedCurrencies.compactMap { currency -> ConvertedCurrencyTotal? in
            guard let amount = netWorthTotal(
                assets,
                liabilities: liabilities,
                to: currency,
                exchangeRates: exchangeRates
            ) else {
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

    func netWorthTrendRows(
        _ snapshots: [NetWorthSnapshot],
        baseCurrency: Asset.CurrencyType,
        limit: Int = 30
    ) -> [NetWorthTrendRow] {
        snapshots
            .filter { $0.displayCurrencyCode == baseCurrency.rawValue }
            .sorted { $0.displayRecordedAt < $1.displayRecordedAt }
            .suffix(limit)
            .map { snapshot in
                NetWorthTrendRow(
                    recordedAt: snapshot.displayRecordedAt,
                    amount: snapshot.displayAmount,
                    currencyCode: snapshot.displayCurrencyCode
                )
            }
    }

    func recentAssetHistoryRows(
        _ snapshots: [AssetValueSnapshot],
        limit: Int = 5
    ) -> [AssetHistoryRow] {
        snapshots
            .sorted { $0.displayRecordedAt > $1.displayRecordedAt }
            .prefix(limit)
            .map { snapshot in
                AssetHistoryRow(
                    assetName: snapshot.displayAssetName,
                    amount: snapshot.displayAmount,
                    currencyCode: snapshot.displayCurrencyCode,
                    categoryName: snapshot.displayCategoryName,
                    recordedAt: snapshot.displayRecordedAt
                )
            }
    }

    func recordPortfolioHistory(
        assets: [Asset],
        liabilities: [Liability] = [],
        baseCurrency: Asset.CurrencyType,
        netWorthSnapshots: [NetWorthSnapshot],
        assetValueSnapshots: [AssetValueSnapshot],
        modelContext: ModelContext
    ) {
        guard !assets.isEmpty || !liabilities.isEmpty else {
            return
        }

        recordAssetValueSnapshots(
            assets: assets,
            existingSnapshots: assetValueSnapshots,
            modelContext: modelContext
        )

        guard let netWorth = netWorthTotal(
            assets,
            liabilities: liabilities,
            to: baseCurrency,
            exchangeRates: exchangeRates
        ) else {
            return
        }

        let latestSnapshot = netWorthSnapshots
            .filter { $0.displayCurrencyCode == baseCurrency.rawValue }
            .max { $0.displayRecordedAt < $1.displayRecordedAt }

        guard shouldRecordNetWorthSnapshot(netWorth, after: latestSnapshot) else {
            return
        }

        modelContext.insert(
            NetWorthSnapshot(
                amount: netWorth,
                currencyCode: baseCurrency.rawValue
            )
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

    private func recordAssetValueSnapshots(
        assets: [Asset],
        existingSnapshots: [AssetValueSnapshot],
        modelContext: ModelContext
    ) {
        let latestSnapshotsByAsset = Dictionary(
            grouping: existingSnapshots,
            by: \.displayAssetIdentifier
        ).compactMapValues { snapshots in
            snapshots.max { $0.displayRecordedAt < $1.displayRecordedAt }
        }

        for asset in assets {
            let identifier = assetHistoryIdentifier(for: asset)
            let latestSnapshot = assetHistoryIdentifiers(for: asset)
                .compactMap { latestSnapshotsByAsset[$0] }
                .max { $0.displayRecordedAt < $1.displayRecordedAt }
            guard shouldRecordAssetSnapshot(asset, after: latestSnapshot) else {
                continue
            }

            modelContext.insert(
                AssetValueSnapshot(
                    assetIdentifier: identifier,
                    assetName: asset.displayName,
                    amount: asset.displayAmount,
                    currencyCode: asset.displayCurrency.rawValue,
                    categoryName: asset.displayCategory.rawValue
                )
            )
        }
    }

    private func shouldRecordAssetSnapshot(_ asset: Asset, after snapshot: AssetValueSnapshot?) -> Bool {
        guard let snapshot else {
            return true
        }

        return abs(snapshot.displayAmount - asset.displayAmount) >= 0.01
    }

    private func shouldRecordNetWorthSnapshot(_ amount: Double, after snapshot: NetWorthSnapshot?) -> Bool {
        guard let snapshot else {
            return true
        }

        return abs(snapshot.displayAmount - amount) >= 0.01
    }

    private func assetHistoryIdentifier(for asset: Asset) -> String {
        asset.stableHistoryIdentifier
    }

    private func assetHistoryIdentifiers(for asset: Asset) -> [String] {
        [
            assetHistoryIdentifier(for: asset),
            legacyAssetHistoryIdentifier(for: asset)
        ].reduce(into: [String]()) { identifiers, identifier in
            guard !identifier.isEmpty, !identifiers.contains(identifier) else {
                return
            }
            identifiers.append(identifier)
        }
    }

    private func legacyAssetHistoryIdentifier(for asset: Asset) -> String {
        String(describing: asset.persistentModelID)
    }
}

struct CurrencyTotal: Identifiable {
    let currency: Asset.CurrencyType
    let amount: Double

    var id: String { currency.rawValue }
}

struct CategoryAllocationRow: Identifiable {
    let category: Asset.CategoryType
    let amount: Double
    let percentage: Double

    var id: String { category.rawValue }
}

struct NetWorthTrendRow: Identifiable {
    let recordedAt: Date
    let amount: Double
    let currencyCode: String

    var id: String { "\(currencyCode)-\(recordedAt.timeIntervalSince1970)" }
}

struct AssetHistoryRow: Identifiable {
    let assetName: String
    let amount: Double
    let currencyCode: String
    let categoryName: String
    let recordedAt: Date

    var id: String { "\(assetName)-\(currencyCode)-\(recordedAt.timeIntervalSince1970)" }
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
