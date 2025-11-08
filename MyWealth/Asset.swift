//
//  Asset.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//


import SwiftUI
import SwiftData
import Charts

@Model
final class Asset {
    var name: String
    var amount: Double
    var currency: CurrencyType
    var category: CategoryType
    
    init(name: String, amount: Double, currency: CurrencyType, category: CategoryType) {
        self.name = name
        self.amount = amount
        self.currency = currency
        self.category = category
    }
    
    enum CurrencyType: String, Codable, CaseIterable, Identifiable {
        case usd = "USD"
        case inr = "INR"
        var id: String { rawValue }
    }
    
    enum CategoryType: String, Codable, CaseIterable, Identifiable {
        case stocks = "Stocks"
        case realEstate = "Real Estate"
        case crypto = "Crypto"
        case bank = "Bank Deposits"
        case mutualFunds = "Mutual Funds"
        case others = "Others"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .stocks: "chart.line.uptrend.xyaxis"
            case .realEstate: "house.fill"
            case .crypto: "bitcoinsign.circle"
            case .bank: "banknote"
            case .mutualFunds: "chart.pie"
            case .others: "tray.full"
            }
        }
    }
}