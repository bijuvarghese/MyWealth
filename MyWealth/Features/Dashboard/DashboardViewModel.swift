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
    
    /// True when the cached rates predate the server's most recent 8-hour refresh boundary (00:00 / 08:00 / 16:00 UTC).
    var ratesAreStale: Bool {
        guard let lastUpdated else { return true }
        return lastUpdated < Self.lastCacheBoundary(before: Date())
    }

    private static func lastCacheBoundary(before date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let hours = cal.component(.hour, from: date)
        let boundaryHour = (hours / 8) * 8
        return cal.date(bySettingHour: boundaryHour, minute: 0, second: 0, of: date)!
    }

    @MainActor
    func refreshExchangeRateIfNeeded(requiredCurrencies: [Asset.CurrencyType] = []) async {
        guard !isLoadingRate else {
            return
        }
        await fetchExchangeRate(requiredCurrencies: requiredCurrencies)
    }

    @MainActor
    func refreshExchangeRateIfStale(requiredCurrencies: [Asset.CurrencyType] = []) async {
        guard ratesAreStale else { return }
        await refreshExchangeRateIfNeeded(requiredCurrencies: requiredCurrencies)
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

            let lastUpdatedAt = decoded.cacheUpdatedAt ?? decoded.providerUpdatedAt ?? Date()
            exchangeRates = rates
            exchangeRate = rates["INR"] ?? exchangeRate
            lastUpdated = lastUpdatedAt
            rateErrorMessage = missingRateCodes.isEmpty
                ? nil
                : "Exchange rates are missing \(missingRateCodes.joined(separator: ", ")). Totals may be incomplete."
            persistRates(rates, inrRate: exchangeRate, at: lastUpdatedAt)
        } catch {
            rateErrorMessage = AppLocalization.string(
                "Unable to refresh exchange rates. Showing the last saved rates."
            )
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
            .filter { $0.1 > 0 }
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

    func liabilityAllocationRows(
        _ liabilities: [Liability],
        targetCurrency: Asset.CurrencyType
    ) -> [LiabilityAllocationRow] {
        let dict = Dictionary(grouping: liabilities) { $0.displayCategory }
        let totals = dict.map { category, group -> (Liability.CategoryType, Double) in
            let total = group.reduce(0.0) { sum, liability in
                sum + convertLiabilityAmount(liability, to: targetCurrency)
            }
            return (category, total)
        }
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }

        let grandTotal = totals.reduce(0) { $0 + $1.1 }
        guard grandTotal > 0 else { return [] }

        return totals.map { category, amount in
            LiabilityAllocationRow(
                category: category,
                amount: amount,
                percentage: amount / grandTotal
            )
        }
    }

    private func convertLiabilityAmount(_ liability: Liability, to targetCurrency: Asset.CurrencyType) -> Double {
        let sourceCurrency = liability.displayCurrency
        if sourceCurrency == targetCurrency { return liability.displayAmount }
        let sourceRate: Double
        if sourceCurrency == .usd {
            sourceRate = 1
        } else {
            guard let r = exchangeRates[sourceCurrency.rawValue], r > 0 else { return 0 }
            sourceRate = r
        }
        let targetRate: Double
        if targetCurrency == .usd {
            targetRate = 1
        } else {
            guard let r = exchangeRates[targetCurrency.rawValue], r > 0 else { return 0 }
            targetRate = r
        }
        return (liability.displayAmount / sourceRate) * targetRate
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

    /// Merges metal-price rates (symbol → units-of-metal-per-USD) into `exchangeRates`
    /// for any symbol not already provided by the forex API.
    ///
    /// Both APIs use the same USD-base convention, so the values are directly
    /// compatible:  `exchangeRates["XAU"]` ≈ `metalRates["XAU"]` ≈ troy-oz-per-USD.
    ///
    /// Call this after both the forex and metal price fetches have settled.
    func enrichWithMetalRates(_ metalRates: [String: Double]) {
        for (symbol, rate) in metalRates where exchangeRates[symbol] == nil {
            exchangeRates[symbol] = rate
        }
    }

    var rateStatus: RateStatusModel? {
        if isLoadingRate {
            return RateStatusModel(
                systemImage: "arrow.triangle.2.circlepath",
                message: AppLocalization.string("Refreshing exchange rates..."),
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
                message: AppLocalization.string("Exchange rates have not been refreshed yet."),
                style: .neutral
            )
        }

        if !Calendar.current.isDateInToday(lastUpdated) {
            return RateStatusModel(
                systemImage: "clock.badge.exclamationmark",
                message: AppLocalization.formatted(
                    "Exchange rates are from %@.",
                    arguments: [lastUpdated.formatted(date: .abbreviated, time: .shortened)]
                ),
                style: .warning
            )
        }

        // Happy path — always show a freshness indicator so the banner is visible.
        return RateStatusModel(
            systemImage: "checkmark.circle",
            message: AppLocalization.formatted(
                "Updated %@",
                arguments: [lastUpdated.formatted(.relative(presentation: .numeric))]
            ),
            style: .neutral
        )
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

    func portfolioTrendRows(
        _ snapshots: [PortfolioSnapshot],
        baseCurrency: Asset.CurrencyType,
        limit: Int = 30
    ) -> [PortfolioTrendRow] {
        snapshots
            .filter { $0.displayCurrencyCode == baseCurrency.rawValue }
            .sorted { $0.displayRecordedAt < $1.displayRecordedAt }
            .suffix(limit)
            .enumerated()
            .map { offset, snapshot in
                PortfolioTrendRow(
                    id: "\(snapshot.persistentModelID)-\(offset)",
                    recordedAt: snapshot.displayRecordedAt,
                    assetTotal: snapshot.displayAssetTotal,
                    liabilityTotal: snapshot.displayLiabilityTotal,
                    currencyCode: snapshot.displayCurrencyCode
                )
            }
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
            .enumerated()
            .map { offset, snapshot in
                NetWorthTrendRow(
                    id: [
                        String(describing: snapshot.persistentModelID),
                        snapshot.displayCurrencyCode,
                        "\(snapshot.displayRecordedAt.timeIntervalSince1970)",
                        "\(snapshot.displayAmount)",
                        "\(offset)"
                    ].joined(separator: "-"),
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
            .enumerated()
            .map { offset, snapshot in
                AssetHistoryRow(
                    id: [
                        String(describing: snapshot.persistentModelID),
                        snapshot.displayAssetIdentifier,
                        snapshot.displayAssetName,
                        snapshot.displayCurrencyCode,
                        "\(snapshot.displayRecordedAt.timeIntervalSince1970)",
                        "\(snapshot.displayAmount)",
                        "\(offset)"
                    ].joined(separator: "-"),
                    assetName: snapshot.displayAssetName,
                    amount: snapshot.displayAmount,
                    currencyCode: snapshot.displayCurrencyCode,
                    categoryName: snapshot.displayCategoryName,
                    recordedAt: snapshot.displayRecordedAt,
                    isManual: snapshot.isManual ?? false,
                    note: snapshot.note
                )
            }
    }

    func assetHistoryRows(
        for asset: Asset,
        snapshots: [AssetValueSnapshot],
        limit: Int? = nil
    ) -> [AssetHistoryRow] {
        let identifiers = Set(assetHistoryIdentifiers(for: asset))
        let rows = snapshots
            .filter { identifiers.contains($0.displayAssetIdentifier) }
            .sorted { $0.displayRecordedAt > $1.displayRecordedAt }

        return rows
            .prefix(limit ?? rows.count)
            .enumerated()
            .map { offset, snapshot in
                AssetHistoryRow(
                    id: [
                        String(describing: snapshot.persistentModelID),
                        snapshot.displayAssetIdentifier,
                        snapshot.displayAssetName,
                        snapshot.displayCurrencyCode,
                        "\(snapshot.displayRecordedAt.timeIntervalSince1970)",
                        "\(snapshot.displayAmount)",
                        "\(offset)"
                    ].joined(separator: "-"),
                    assetName: snapshot.displayAssetName,
                    amount: snapshot.displayAmount,
                    currencyCode: snapshot.displayCurrencyCode,
                    categoryName: snapshot.displayCategoryName,
                    recordedAt: snapshot.displayRecordedAt,
                    isManual: snapshot.isManual ?? false,
                    note: snapshot.note
                )
            }
    }

    /// Inserts a user-authored `AssetValueSnapshot` for a non-market asset.
    /// Unlike automatic snapshots, manual entries always persist regardless of
    /// whether the amount has changed, and carry the user-supplied date and note.
    func logManualValueEntry(
        for asset: Asset,
        amount: Double,
        date: Date,
        note: String?,
        modelContext: ModelContext
    ) {
        let snapshot = AssetValueSnapshot(
            assetIdentifier: asset.stableHistoryIdentifier,
            assetName: asset.displayName,
            amount: amount,
            currencyCode: asset.displayCurrency.rawValue,
            categoryName: asset.displayCategory.rawValue,
            recordedAt: date,
            isManual: true,
            note: note
        )
        modelContext.insert(snapshot)
    }

    func portfolioInsightRows(
        assets: [Asset],
        liabilities: [Liability],
        netWorthSnapshots: [NetWorthSnapshot],
        baseCurrency: Asset.CurrencyType,
        limit: Int = 5
    ) -> [PortfolioInsightRow] {
        var rows: [PortfolioInsightRow] = []

        let assetTotal = convertedTotal(assets, to: baseCurrency, exchangeRates: exchangeRates)
        let liabilityTotal = convertedLiabilityTotal(liabilities, to: baseCurrency, exchangeRates: exchangeRates)
        let netWorth = assetTotal.flatMap { a in liabilityTotal.map { l in a - l } }
        let allocationRows = categoryAllocationRows(assets, targetCurrency: baseCurrency)

        // 1. Net worth change since earliest snapshot
        let sortedSnapshots = netWorthSnapshots
            .filter { $0.displayCurrencyCode == baseCurrency.rawValue }
            .sorted { $0.displayRecordedAt < $1.displayRecordedAt }
        if let earliest = sortedSnapshots.first, let latest = sortedSnapshots.last,
           earliest.persistentModelID != latest.persistentModelID,
           abs(earliest.displayAmount) > 0.01 {
            let change = latest.displayAmount - earliest.displayAmount
            let pct = change / abs(earliest.displayAmount)
            let isUp = change >= 0
            let formatted = abs(pct).formatted(.percent.precision(.fractionLength(1)))
            let days = Calendar.current.dateComponents([.day], from: earliest.displayRecordedAt, to: latest.displayRecordedAt).day ?? 0
            let timeLabel = days < 30 ? "\(days)d" : days < 365 ? "\(days / 30)mo" : "\(days / 365)yr"
            rows.append(PortfolioInsightRow(
                systemImage: isUp ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                message: AppLocalization.formatted(
                    isUp
                        ? "Net worth up %@ over the last %@."
                        : "Net worth down %@ over the last %@.",
                    arguments: [formatted, timeLabel]
                ),
                sentiment: isUp ? .positive : .warning
            ))
        }

        // 2. Debt-to-asset ratio with health label
        if let a = assetTotal, let l = liabilityTotal, a > 0, l > 0, a.isFinite, l.isFinite {
            let ratio = l / a
            let pct = safePercentInt(ratio)
            let (label, sentiment): (String, PortfolioInsightRow.Sentiment) = {
                if ratio < 0.20 { return (AppLocalization.string("healthy"), .positive) }
                if ratio < 0.50 { return (AppLocalization.string("elevated"), .neutral) }
                return (AppLocalization.string("high"), .warning)
            }()
            rows.append(PortfolioInsightRow(
                systemImage: sentiment == .positive ? "checkmark.shield.fill" : "exclamationmark.triangle.fill",
                message: AppLocalization.formatted(
                    "Debt-to-asset ratio is %lld%% — %@.",
                    arguments: [pct, label]
                ),
                sentiment: sentiment
            ))
        }

        // 3. Concentration risk — single category > 60%
        if let dominant = allocationRows.first, dominant.percentage > 0.60 {
            rows.append(PortfolioInsightRow(
                systemImage: "exclamationmark.circle.fill",
                message: AppLocalization.formatted(
                    "%lld%% of assets are in %@. Consider diversifying.",
                    arguments: [
                        safePercentInt(dominant.percentage),
                        dominant.category.localizedName
                    ]
                ),
                sentiment: .warning
            ))
        } else if let largest = allocationRows.first {
            // Non-concerning allocation summary
            rows.append(PortfolioInsightRow(
                systemImage: largest.category.icon,
                message: AppLocalization.formatted(
                    "%lld%% of assets are in %@.",
                    arguments: [
                        safePercentInt(largest.percentage),
                        largest.category.localizedName
                    ]
                ),
                sentiment: .neutral
            ))
        }

        // 4. Asset count and diversification
        let categoryCount = allocationRows.count
        if categoryCount >= 4 {
            rows.append(PortfolioInsightRow(
                systemImage: "chart.pie.fill",
                message: AppLocalization.formatted(
                    "Portfolio spans %lld categories — well diversified.",
                    arguments: [categoryCount]
                ),
                sentiment: .positive
            ))
        } else if categoryCount == 1, assets.count > 1 {
            rows.append(PortfolioInsightRow(
                systemImage: "chart.pie",
                message: AppLocalization.string(
                    "All assets are in one category. Adding more categories reduces risk."
                ),
                sentiment: .warning
            ))
        }

        // 5. Stale asset warning — not updated in 60+ days
        let staleThreshold: TimeInterval = 60 * 86400
        let staleAssets = assets.filter { asset in
            guard let updated = asset.lastUpdated else { return true }
            return Date().timeIntervalSince(updated) > staleThreshold
        }
        if !staleAssets.isEmpty {
            let names = staleAssets.prefix(2).map {
                $0.displayName.isEmpty ? AppLocalization.string("Unnamed") : $0.displayName
            }.joined(separator: ", ")
            let suffix = staleAssets.count > 2
                ? AppLocalization.formatted(
                    " and %lld more",
                    arguments: [staleAssets.count - 2]
                )
                : ""
            rows.append(PortfolioInsightRow(
                systemImage: "clock.badge.exclamationmark.fill",
                message: AppLocalization.formatted(
                    staleAssets.count == 1
                        ? "%@%@ hasn't been updated in 60+ days."
                        : "%@%@ haven't been updated in 60+ days.",
                    arguments: [names, suffix]
                ),
                sentiment: .warning
            ))
        }

        // 6. Cash buffer check — bank < 5% with liabilities present
        if let bankRow = allocationRows.first(where: { $0.category == .bank }),
           !liabilities.isEmpty, bankRow.percentage < 0.05 {
            rows.append(PortfolioInsightRow(
                systemImage: "building.columns.fill",
                message: AppLocalization.string(
                    "Cash & deposits are under 5% of assets. A small buffer helps cover liabilities."
                ),
                sentiment: .warning
            ))
        }

        // 7. Net worth milestone crossing (positive round numbers)
        let milestones: [Double] = [10_000, 25_000, 50_000, 100_000, 250_000, 500_000, 1_000_000, 2_000_000, 5_000_000]
        if let nw = netWorth, nw > 0, let previous = sortedSnapshots.dropLast().last {
            for milestone in milestones {
                if nw >= milestone && previous.displayAmount < milestone {
                    let milestoneFormatted = milestone.formatted(.currency(code: baseCurrency.rawValue).precision(.fractionLength(0)))
                    rows.append(PortfolioInsightRow(
                        systemImage: "star.circle.fill",
                        message: AppLocalization.formatted(
                            "Milestone reached! Net worth crossed %@.",
                            arguments: [milestoneFormatted]
                        ),
                        sentiment: .positive
                    ))
                    break
                }
            }
        }

        // 8. Largest single asset
        if let topAsset = assets.max(by: { ($0.displayAmount) < ($1.displayAmount) }),
           let total = assetTotal, total > 0 {
            let topConverted = convertedTotal([topAsset], to: baseCurrency, exchangeRates: exchangeRates) ?? 0
            let share = topConverted / total
            if share > 0.40 {
                let name = topAsset.displayName.isEmpty
                    ? AppLocalization.string("one asset")
                    : topAsset.displayName
                rows.append(PortfolioInsightRow(
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    message: AppLocalization.formatted(
                        "%lld%% of assets are in %@ alone.",
                        arguments: [safePercentInt(share), name]
                    ),
                    sentiment: share > 0.70 ? .warning : .neutral
                ))
            }
        }

        // 9. Precious metals exposure
        let metalCategories: Set<Asset.CategoryType> = [.gold, .silver, .platinum, .palladium, .rhodium]
        let hasMetal = allocationRows.contains(where: { metalCategories.contains($0.category) })
        if hasMetal {
            let totalMetalPct = allocationRows
                .filter { metalCategories.contains($0.category) }
                .reduce(0) { $0 + $1.percentage }
            if totalMetalPct > 0.10 {
                rows.append(PortfolioInsightRow(
                    systemImage: "cube.fill",
                    message: AppLocalization.formatted(
                        "%lld%% of assets are in precious metals.",
                        arguments: [safePercentInt(totalMetalPct)]
                    ),
                    sentiment: .neutral
                ))
            }
        }

        // 10. Fallback
        if rows.isEmpty {
            rows.append(PortfolioInsightRow(
                systemImage: "sparkles",
                message: AppLocalization.string(
                    "Add assets or update values to unlock portfolio insights."
                ),
                sentiment: .neutral
            ))
        }

        return Array(rows.prefix(limit))
    }

    // Safely converts a 0…1 ratio to an integer percentage, returning 0 if the
    // input is NaN or infinite. Prevents an Int(Double) trap when upstream
    // math (e.g. division by a missing/zero exchange rate) yields a non-finite
    // value.
    private func safePercentInt(_ ratio: Double) -> Int {
        let scaled = ratio * 100
        guard scaled.isFinite else { return 0 }
        return Int(scaled.rounded())
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

        // Same stale-@Query problem applies to net worth snapshots: fetch fresh.
        let freshNetWorthSnapshots: [NetWorthSnapshot]
        do {
            freshNetWorthSnapshots = try modelContext.fetch(FetchDescriptor<NetWorthSnapshot>())
        } catch {
            freshNetWorthSnapshots = netWorthSnapshots
        }

        let latestSnapshot = freshNetWorthSnapshots
            .filter { $0.displayCurrencyCode == baseCurrency.rawValue }
            .max { $0.displayRecordedAt < $1.displayRecordedAt }

        if shouldRecordNetWorthSnapshot(netWorth, after: latestSnapshot) {
            modelContext.insert(
                NetWorthSnapshot(
                    amount: netWorth,
                    currencyCode: baseCurrency.rawValue
                )
            )
        }

        // Record PortfolioSnapshot for the assets-vs-liabilities trend chart.
        recordPortfolioSnapshot(
            assets: assets,
            liabilities: liabilities,
            baseCurrency: baseCurrency,
            modelContext: modelContext
        )
    }

    private func recordPortfolioSnapshot(
        assets: [Asset],
        liabilities: [Liability],
        baseCurrency: Asset.CurrencyType,
        modelContext: ModelContext
    ) {
        guard
            let assetTotal = convertedTotal(assets, to: baseCurrency, exchangeRates: exchangeRates),
            let liabilityTotal = convertedLiabilityTotal(liabilities, to: baseCurrency, exchangeRates: exchangeRates)
        else { return }

        let freshPortfolioSnapshots: [PortfolioSnapshot]
        do {
            freshPortfolioSnapshots = try modelContext.fetch(FetchDescriptor<PortfolioSnapshot>())
        } catch {
            freshPortfolioSnapshots = []
        }

        let latest = freshPortfolioSnapshots
            .filter { $0.displayCurrencyCode == baseCurrency.rawValue }
            .max { $0.displayRecordedAt < $1.displayRecordedAt }

        let hasChanged = latest.map {
            abs($0.displayAssetTotal - assetTotal) >= 0.01 ||
            abs($0.displayLiabilityTotal - liabilityTotal) >= 0.01
        } ?? true

        guard hasChanged else { return }

        modelContext.insert(PortfolioSnapshot(
            assetTotal: assetTotal,
            liabilityTotal: liabilityTotal,
            currencyCode: baseCurrency.rawValue
        ))
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
        // Fetch snapshots directly from the model context rather than using the
        // @Query-sourced `existingSnapshots` array. The @Query result is a
        // snapshot of the last render cycle and does NOT include objects inserted
        // earlier in the same run loop. Without this, two back-to-back calls to
        // recordPortfolioHistory (e.g. triggered by both assetSnapshotSignature
        // and rateSnapshotSignature changing together) both see the pre-insert
        // state and record identical duplicate entries.
        let freshSnapshots: [AssetValueSnapshot]
        do {
            freshSnapshots = try modelContext.fetch(FetchDescriptor<AssetValueSnapshot>())
        } catch {
            freshSnapshots = existingSnapshots
        }

        let latestSnapshotsByAsset = Dictionary(
            grouping: freshSnapshots,
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

        return abs(snapshot.displayAmount - asset.displayAmount) >= 0.01 ||
            snapshot.displayCurrencyCode != asset.displayCurrency.rawValue
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

struct LiabilityAllocationRow: Identifiable {
    let category: Liability.CategoryType
    let amount: Double
    let percentage: Double

    var id: String { category.rawValue }
}

struct NetWorthTrendRow: Identifiable {
    let id: String
    let recordedAt: Date
    let amount: Double
    let currencyCode: String
}

struct PortfolioTrendRow: Identifiable {
    let id: String
    let recordedAt: Date
    let assetTotal: Double
    let liabilityTotal: Double
    let currencyCode: String
}

struct AssetHistoryRow: Identifiable {
    let id: String
    let assetName: String
    let amount: Double
    let currencyCode: String
    let categoryName: String
    let recordedAt: Date
    var isManual: Bool = false
    var note: String? = nil
}

struct PortfolioInsightRow: Identifiable {
    enum Sentiment { case positive, neutral, warning }

    let systemImage: String
    let message: String
    var sentiment: Sentiment = .neutral

    var id: String { "\(systemImage)-\(message)" }
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
    let cacheTimestamp: Int?

    var providerUpdatedAt: Date? {
        timestamp.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }

    var cacheUpdatedAt: Date? {
        cacheTimestamp.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }
}
