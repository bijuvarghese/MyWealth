//
//  AssetOperations.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/8/25.
//

protocol AssetOperations {
    func totalInUSD(_ assets: [Asset], exchangeRates: [String: Double]) -> Double?
    func convertedTotal(_ assets: [Asset], to targetCurrency: Asset.CurrencyType, exchangeRates: [String: Double]) -> Double?
    func convertedLiabilityTotal(_ liabilities: [Liability], to targetCurrency: Asset.CurrencyType, exchangeRates: [String: Double]) -> Double?
    func netWorthTotal(_ assets: [Asset], liabilities: [Liability], to targetCurrency: Asset.CurrencyType, exchangeRates: [String: Double]) -> Double?
}

extension AssetOperations {
    func totalInUSD(_ assets: [Asset], exchangeRates: [String: Double]) -> Double? {
        convertedTotal(assets, to: .usd, exchangeRates: exchangeRates)
    }

    func convertedTotal(_ assets: [Asset], to targetCurrency: Asset.CurrencyType, exchangeRates: [String: Double]) -> Double? {
        guard let targetRate = rate(for: targetCurrency, exchangeRates: exchangeRates) else {
            return nil
        }

        var totalInUSD = 0.0
        for asset in assets {
            guard
                let sourceCurrency = asset.currency,
                let amount = asset.amount,
                amount > 0,
                let sourceRate = rate(for: sourceCurrency, exchangeRates: exchangeRates),
                sourceRate > 0
            else {
                // Skip this asset rather than aborting the whole total.
                // A missing rate (e.g. a metal not yet in the forex API) should
                // not wipe out the rest of the portfolio calculation.
                continue
            }

            totalInUSD += amount / sourceRate
        }

        return totalInUSD * targetRate
    }

    func convertedLiabilityTotal(_ liabilities: [Liability], to targetCurrency: Asset.CurrencyType, exchangeRates: [String: Double]) -> Double? {
        guard let targetRate = rate(for: targetCurrency, exchangeRates: exchangeRates) else {
            return nil
        }

        var totalInUSD = 0.0
        for liability in liabilities {
            guard
                let sourceCurrency = liability.currency,
                let amount = liability.amount,
                amount > 0,
                let sourceRate = rate(for: sourceCurrency, exchangeRates: exchangeRates),
                sourceRate > 0
            else {
                continue
            }

            totalInUSD += amount / sourceRate
        }

        return totalInUSD * targetRate
    }

    func netWorthTotal(
        _ assets: [Asset],
        liabilities: [Liability],
        to targetCurrency: Asset.CurrencyType,
        exchangeRates: [String: Double]
    ) -> Double? {
        guard
            let assetTotal = convertedTotal(assets, to: targetCurrency, exchangeRates: exchangeRates),
            let liabilityTotal = convertedLiabilityTotal(liabilities, to: targetCurrency, exchangeRates: exchangeRates)
        else {
            return nil
        }

        return assetTotal - liabilityTotal
    }

    private func rate(for currency: Asset.CurrencyType, exchangeRates: [String: Double]) -> Double? {
        if currency == .usd {
            return 1
        }

        return exchangeRates[currency.rawValue]
    }
}
