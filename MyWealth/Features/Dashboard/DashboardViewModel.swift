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
final class DashboardViewModel {
    var exchangeRate: Double = 84.0
    var isLoadingRate = false
    var lastUpdated: Date? = nil
    
    func fetchExchangeRate() async {
        guard let url = URL(string: "https://api.exchangerate.host/latest?base=USD&symbols=INR") else { return }
        isLoadingRate = true
        defer { isLoadingRate = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(RateResponse.self, from: data)
            if let rate = decoded.rates["INR"] {
                exchangeRate = rate
                lastUpdated = Date()
            }
        } catch {
            print("⚠️ Error fetching rate:", error.localizedDescription)
        }
    }
    
    private struct RateResponse: Codable {
        let rates: [String: Double]
    }
    
    func totalInUSD(_ assets: [Asset]) -> Double {
        assets.reduce(0) { total, a in
            total + (a.currency == .usd ? a.amount : a.amount / exchangeRate)
        }
    }
    
    func totalInINR(_ assets: [Asset]) -> Double {
        assets.reduce(0) { total, a in
            total + (a.currency == .inr ? a.amount : a.amount * exchangeRate)
        }
    }
    
    func groupedByCategory(_ assets: [Asset]) -> [(Asset.CategoryType, Double)] {
        let dict = Dictionary(grouping: assets) { $0.category }
        return dict.map { (key, group) in
            let total = totalInUSD(group)
            return (key, total)
        }.sorted { $0.1 > $1.1 }
    }
}
