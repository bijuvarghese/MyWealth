import Foundation

struct WatchPortfolioSnapshot: Codable {
    let netWorth: Double
    let assetTotal: Double
    let liabilityTotal: Double
    let baseCurrency: String
    let currencyTotals: [CurrencyEntry]
    let lastUpdated: Date
    let transferRatesLastUpdated: Date?

    struct CurrencyEntry: Codable, Identifiable {
        let code: String
        let amount: Double
        let transferRate: Double?

        var id: String { code }
    }

    static var placeholder: WatchPortfolioSnapshot {
        WatchPortfolioSnapshot(
            netWorth: 0,
            assetTotal: 0,
            liabilityTotal: 0,
            baseCurrency: "USD",
            currencyTotals: [],
            lastUpdated: .now,
            transferRatesLastUpdated: nil
        )
    }
}

extension WatchPortfolioSnapshot {
    var preferredCurrency: CurrencyEntry? {
        currencyTotals.first
    }

    var ratesUpdatedAt: Date {
        transferRatesLastUpdated ?? lastUpdated
    }
}
