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
    var name: String?
    var amount: Double?
    var currency: CurrencyType?
    var category: CategoryType?
    var lastUpdated: Date?
    
    init(name: String, amount: Double, currency: CurrencyType, category: CategoryType, lastUpdated: Date? = Date()) {
        self.name = name
        self.amount = amount
        self.currency = currency
        self.category = category
        self.lastUpdated = lastUpdated
    }
    
    enum CurrencyType: String, Codable, CaseIterable, Identifiable {
        case usd = "USD"
        case inr = "INR"
        case none = ""
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

@Model
final class Currencies {
    var symbols: [String: String]?
    var updatedDate: Date?

    init(symbols: [String: String]? = nil, updatedDate: Date? = Date()) {
        self.symbols = symbols
        self.updatedDate = updatedDate
    }
}


struct SymbolsResponse: Codable {
    var success: Bool?
    var symbols: [String: String]?
    var updatedDate: Date?

    init(success: Bool? = nil, symbols: [String: String]? = nil, updatedDate: Date? = Date()) {
        self.success = success
        self.symbols = symbols
        self.updatedDate = updatedDate
    }
}
