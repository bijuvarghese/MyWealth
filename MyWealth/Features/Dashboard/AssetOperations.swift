//
//  AssetOperations.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/8/25.
//

protocol AssetOperations {
    func totalInUSD(_ assets: [Asset], exchangeRate: Double) -> Double
    func totalInINR(_ assets: [Asset], exchangeRate: Double) -> Double
}

extension AssetOperations {
    func totalInUSD(_ assets: [Asset], exchangeRate: Double) -> Double {
        assets.reduce(0.0) { total, a in
            let amount = a.amount ?? 0
            let valueInUSD: Double
            if a.currency == .usd {
                valueInUSD = amount
            } else {
                valueInUSD = amount / exchangeRate
            }
            return total + valueInUSD
        }
    }
    
    func totalInINR(_ assets: [Asset], exchangeRate: Double) -> Double {
        assets.reduce(0.0) { total, a in
            let amount = a.amount ?? 0
            let valueInINR: Double
            if a.currency == .inr {
                valueInINR = amount
            } else {
                valueInINR = amount * exchangeRate
            }
            return total + valueInINR
        }
    }
}
