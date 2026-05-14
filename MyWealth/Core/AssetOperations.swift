//
//  AssetOperations.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/8/25.
//

protocol AssetOperations {
    func totalInUSD(_ assets: [Asset], exchangeRate: Double) -> Double
    func convertedTotal(_ assets: [Asset], to targetCurrency: Asset.CurrencyType, exchangeRates: [String: Double]) -> Double?
}

extension AssetOperations {
    func totalInUSD(_ assets: [Asset], exchangeRate: Double) -> Double {
        assets.reduce(0.0) { total, a in
            let amount = a.amount ?? 0
            guard let currency = a.currency, currency.isSupportedForTotals else {
                return total
            }

            let valueInUSD: Double
            if currency == .usd {
                valueInUSD = amount
            } else {
                valueInUSD = amount / exchangeRate
            }
            return total + valueInUSD
        }
    }
    
    func convertedTotal(_ assets: [Asset], to targetCurrency: Asset.CurrencyType, exchangeRates: [String: Double]) -> Double? {
        guard let targetRate = rate(for: targetCurrency, exchangeRates: exchangeRates) else {
            return nil
        }

        var totalInUSD = 0.0
        for asset in assets {
            guard
                let sourceCurrency = asset.currency,
                let sourceRate = rate(for: sourceCurrency, exchangeRates: exchangeRates)
            else {
                return nil
            }

            totalInUSD += (asset.amount ?? 0) / sourceRate
        }

        return totalInUSD * targetRate
    }

    private func rate(for currency: Asset.CurrencyType, exchangeRates: [String: Double]) -> Double? {
        if currency == .usd {
            return 1
        }

        return exchangeRates[currency.rawValue]
    }
}
