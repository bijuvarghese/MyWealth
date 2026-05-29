import Foundation
import SwiftData

struct ChatGPTAnalysisExportPayload: Codable, Sendable {
    let version: Int
    let product: String
    let exportedAt: Date
    let analysisPrompt: String
    let baseCurrency: String
    let displayCurrencies: [String]
    let analysisCurrencies: [ChatGPTAnalysisCurrency]
    let exchangeRatesLastUpdated: Date?
    let currentSummary: ChatGPTCurrentSummary
    let currencyExposure: [ChatGPTCurrencyExposure]
    let categoryAllocation: [ChatGPTAllocation]
    let liabilityAllocation: [ChatGPTAllocation]
    let assets: [ChatGPTSanitizedHolding]
    let liabilities: [ChatGPTSanitizedHolding]
    let portfolioHistory: [ChatGPTPortfolioHistoryPoint]
    let netWorthHistory: [ChatGPTNetWorthHistoryPoint]
    let exportNotes: [String]

    static let currentVersion = 1
}

struct ChatGPTAnalysisCurrency: Codable, Sendable {
    let code: String
    let name: String
    let convertedNetWorth: Double?
    let countries: [String]
}

struct ChatGPTCurrentSummary: Codable, Sendable {
    let assetTotal: Double?
    let liabilityTotal: Double?
    let netWorth: Double?
    let totalsByCurrency: [ChatGPTCurrencyTotal]
}

struct ChatGPTCurrencyTotal: Codable, Sendable {
    let currency: String
    let amount: Double
}

struct ChatGPTCurrencyExposure: Codable, Sendable {
    let currency: String
    let assetAmount: Double
    let liabilityAmount: Double
    let netAmount: Double
    let assetCount: Int
    let liabilityCount: Int
}

struct ChatGPTAllocation: Codable, Sendable {
    let name: String
    let amount: Double
    let percentage: Double
    let currency: String
}

struct ChatGPTSanitizedHolding: Codable, Sendable {
    let label: String
    let category: String
    let amount: Double
    let currency: String
    let lastUpdated: Date?
    let weightUnit: String?
}

struct ChatGPTPortfolioHistoryPoint: Codable, Sendable {
    let recordedAt: Date
    let assetTotal: Double
    let liabilityTotal: Double
    let netWorth: Double
    let currency: String
}

struct ChatGPTNetWorthHistoryPoint: Codable, Sendable {
    let recordedAt: Date
    let amount: Double
    let currency: String
}

enum ChatGPTAnalysisExporter {
    private static let analysisPrompt = """
    Analyze this Wealth Map portfolio snapshot for global affordability, relocation feasibility, retirement sustainability, currency exposure, and financial comfort in different countries. For every analysis currency, estimate a comfort score for the countries or regions that use that currency, explain the assumptions behind the score, and identify where local cost-of-living, tax, healthcare, housing, and visa constraints could change the conclusion. Highlight risks and follow-up questions before making recommendations. This is educational analysis, not personalized financial, tax, or legal advice.
    """

    @MainActor
    static func buildAnalysisURL(
        context: ModelContext,
        settings: AppSettings,
        exchangeRates: [String: Double],
        exchangeRatesLastUpdated: Date?
    ) throws -> URL {
        let payload = try buildPayload(
            context: context,
            settings: settings,
            exchangeRates: exchangeRates,
            exchangeRatesLastUpdated: exchangeRatesLastUpdated
        )
        let markdown = try buildMarkdown(payload: payload)
        let filename = "Wealth-Map-ChatGPT-Analysis.md"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try markdown.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    @MainActor
    static func buildPayload(
        context: ModelContext,
        settings: AppSettings,
        exchangeRates: [String: Double],
        exchangeRatesLastUpdated: Date?
    ) throws -> ChatGPTAnalysisExportPayload {
        let assets = try context.fetch(FetchDescriptor<Asset>())
        let liabilities = try context.fetch(FetchDescriptor<Liability>())
        let netWorthSnapshots = try context.fetch(FetchDescriptor<NetWorthSnapshot>())
        let portfolioSnapshots = try context.fetch(FetchDescriptor<PortfolioSnapshot>())
        let viewModel = DashboardViewModel(autoRefreshRate: false)
        viewModel.exchangeRates = exchangeRates.merging(["USD": 1]) { current, _ in current }
        viewModel.lastUpdated = exchangeRatesLastUpdated

        let baseCurrency = settings.baseCurrency
        let displayCurrencies = settings.totalCurrencies
        let calculationAssets = settings.portfolioCalculationAssets(from: assets)
        let assetTotal = viewModel.convertedTotal(
            calculationAssets,
            to: baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )
        let liabilityTotal = viewModel.convertedLiabilityTotal(
            liabilities,
            to: baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )
        let netWorth = viewModel.netWorthTotal(
            calculationAssets,
            liabilities: liabilities,
            to: baseCurrency,
            exchangeRates: viewModel.exchangeRates
        )

        return ChatGPTAnalysisExportPayload(
            version: ChatGPTAnalysisExportPayload.currentVersion,
            product: "Wealth Map",
            exportedAt: Date(),
            analysisPrompt: analysisPrompt,
            baseCurrency: baseCurrency.rawValue,
            displayCurrencies: displayCurrencies.map(\.rawValue),
            analysisCurrencies: analysisCurrencies(
                currencies: displayCurrencies,
                assets: calculationAssets,
                liabilities: liabilities,
                viewModel: viewModel
            ),
            exchangeRatesLastUpdated: exchangeRatesLastUpdated,
            currentSummary: ChatGPTCurrentSummary(
                assetTotal: assetTotal,
                liabilityTotal: liabilityTotal,
                netWorth: netWorth,
                totalsByCurrency: viewModel.totalsByCurrency(
                    calculationAssets,
                    liabilities: liabilities,
                    baseCurrency: baseCurrency,
                    displayCurrencies: displayCurrencies
                )
                .map { ChatGPTCurrencyTotal(currency: $0.currency.rawValue, amount: $0.amount) }
            ),
            currencyExposure: currencyExposure(assets: calculationAssets, liabilities: liabilities),
            categoryAllocation: viewModel.categoryAllocationRows(calculationAssets, targetCurrency: baseCurrency)
                .map {
                    ChatGPTAllocation(
                        name: $0.category.rawValue,
                        amount: $0.amount,
                        percentage: $0.percentage,
                        currency: baseCurrency.rawValue
                    )
                },
            liabilityAllocation: viewModel.liabilityAllocationRows(liabilities, targetCurrency: baseCurrency)
                .map {
                    ChatGPTAllocation(
                        name: $0.category.rawValue,
                        amount: $0.amount,
                        percentage: $0.percentage,
                        currency: baseCurrency.rawValue
                    )
                },
            assets: sanitizedAssets(calculationAssets),
            liabilities: sanitizedLiabilities(liabilities),
            portfolioHistory: viewModel.portfolioTrendRows(portfolioSnapshots, baseCurrency: baseCurrency)
                .map {
                    ChatGPTPortfolioHistoryPoint(
                        recordedAt: $0.recordedAt,
                        assetTotal: $0.assetTotal,
                        liabilityTotal: $0.liabilityTotal,
                        netWorth: $0.assetTotal - $0.liabilityTotal,
                        currency: $0.currencyCode
                    )
                },
            netWorthHistory: viewModel.netWorthTrendRows(netWorthSnapshots, baseCurrency: baseCurrency)
                .map {
                    ChatGPTNetWorthHistoryPoint(
                        recordedAt: $0.recordedAt,
                        amount: $0.amount,
                        currency: $0.currencyCode
                    )
                },
            exportNotes: [
                "Holdings are anonymized as Asset 1, Asset 2, Liability 1, etc.; app-internal identifiers and original names are not included.",
                "Amounts are exported as stored in Wealth Map. Currency conversions depend on the exchange-rate cache available on this device.",
                "Use this export for planning conversations and scenario analysis; verify important decisions with qualified professionals."
            ]
        )
    }

    private static func buildMarkdown(payload: ChatGPTAnalysisExportPayload) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        let exportedAt = ISO8601DateFormatter().string(from: payload.exportedAt)

        return """
        # Wealth Map ChatGPT Analysis Export

        Exported at: \(exportedAt)

        ## Prompt

        \(payload.analysisPrompt)

        ## Portfolio Snapshot

        ```json
        \(json)
        ```
        """
    }

    private static func sanitizedAssets(_ assets: [Asset]) -> [ChatGPTSanitizedHolding] {
        assets
            .sorted { lhs, rhs in
                if lhs.displayCategory.rawValue == rhs.displayCategory.rawValue {
                    return lhs.displayCurrency.rawValue < rhs.displayCurrency.rawValue
                }
                return lhs.displayCategory.rawValue < rhs.displayCategory.rawValue
            }
            .enumerated()
            .map { offset, asset in
                ChatGPTSanitizedHolding(
                    label: "Asset \(offset + 1)",
                    category: asset.displayCategory.rawValue,
                    amount: asset.displayAmount,
                    currency: asset.displayCurrency.rawValue,
                    lastUpdated: asset.lastUpdated,
                    weightUnit: asset.weightUnit?.rawValue
                )
            }
    }

    private static func sanitizedLiabilities(_ liabilities: [Liability]) -> [ChatGPTSanitizedHolding] {
        liabilities
            .sorted { lhs, rhs in
                if lhs.displayCategory.rawValue == rhs.displayCategory.rawValue {
                    return lhs.displayCurrency.rawValue < rhs.displayCurrency.rawValue
                }
                return lhs.displayCategory.rawValue < rhs.displayCategory.rawValue
            }
            .enumerated()
            .map { offset, liability in
                ChatGPTSanitizedHolding(
                    label: "Liability \(offset + 1)",
                    category: liability.displayCategory.rawValue,
                    amount: liability.displayAmount,
                    currency: liability.displayCurrency.rawValue,
                    lastUpdated: liability.lastUpdated,
                    weightUnit: nil
                )
            }
    }

    private static func analysisCurrencies(
        currencies: [Asset.CurrencyType],
        assets: [Asset],
        liabilities: [Liability],
        viewModel: DashboardViewModel
    ) -> [ChatGPTAnalysisCurrency] {
        currencies.map { currency in
            ChatGPTAnalysisCurrency(
                code: currency.rawValue,
                name: currency.name,
                convertedNetWorth: viewModel.netWorthTotal(
                    assets,
                    liabilities: liabilities,
                    to: currency,
                    exchangeRates: viewModel.exchangeRates
                ),
                countries: countriesUsingCurrency(currency.rawValue)
            )
        }
    }

    private static func countriesUsingCurrency(_ currencyCode: String) -> [String] {
        let countries = Locale.availableIdentifiers.compactMap { identifier -> String? in
            let locale = Locale(identifier: identifier)
            guard locale.currency?.identifier == currencyCode else {
                return nil
            }

            guard
                let regionCode = locale.region?.identifier,
                let countryName = Locale.current.localizedString(forRegionCode: regionCode)
            else {
                return nil
            }

            return countryName
        }

        return Array(Set(countries)).sorted()
    }

    private static func currencyExposure(
        assets: [Asset],
        liabilities: [Liability]
    ) -> [ChatGPTCurrencyExposure] {
        let assetGroups = Dictionary(grouping: assets) { $0.displayCurrency.rawValue }
        let liabilityGroups = Dictionary(grouping: liabilities) { $0.displayCurrency.rawValue }
        let currencies = Set(assetGroups.keys).union(liabilityGroups.keys)

        return currencies
            .filter { !$0.isEmpty }
            .sorted()
            .map { currency in
                let currencyAssets = assetGroups[currency] ?? []
                let currencyLiabilities = liabilityGroups[currency] ?? []
                let assetAmount = currencyAssets.reduce(0) { $0 + $1.displayAmount }
                let liabilityAmount = currencyLiabilities.reduce(0) { $0 + $1.displayAmount }

                return ChatGPTCurrencyExposure(
                    currency: currency,
                    assetAmount: assetAmount,
                    liabilityAmount: liabilityAmount,
                    netAmount: assetAmount - liabilityAmount,
                    assetCount: currencyAssets.count,
                    liabilityCount: currencyLiabilities.count
                )
            }
    }
}
