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
        guard
            let targetRate = rate(for: targetCurrency, exchangeRates: exchangeRates),
            targetRate.isFinite, targetRate > 0
        else {
            return nil
        }

        var totalInUSD = 0.0
        for asset in assets {
            guard let amount = asset.amount, amount > 0, amount.isFinite else {
                continue
            }
            guard
                let sourceCurrency = asset.currency,
                sourceCurrency != .none,
                let sourceRate = rate(for: sourceCurrency, exchangeRates: exchangeRates),
                sourceRate > 0, sourceRate.isFinite
            else {
                return nil
            }

            totalInUSD += amount / sourceRate
        }

        let result = totalInUSD * targetRate
        return result.isFinite ? result : nil
    }

    func convertedLiabilityTotal(_ liabilities: [Liability], to targetCurrency: Asset.CurrencyType, exchangeRates: [String: Double]) -> Double? {
        guard
            let targetRate = rate(for: targetCurrency, exchangeRates: exchangeRates),
            targetRate.isFinite, targetRate > 0
        else {
            return nil
        }

        var totalInUSD = 0.0
        for liability in liabilities {
            guard let amount = liability.amount, amount > 0, amount.isFinite else {
                continue
            }
            guard
                let sourceCurrency = liability.currency,
                sourceCurrency != .none,
                let sourceRate = rate(for: sourceCurrency, exchangeRates: exchangeRates),
                sourceRate > 0, sourceRate.isFinite
            else {
                return nil
            }

            totalInUSD += amount / sourceRate
        }

        let result = totalInUSD * targetRate
        return result.isFinite ? result : nil
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
