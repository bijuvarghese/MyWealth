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

    var exchangeRate: Double = 0
    var isLoadingRate = false
    var lastUpdated: Date? = nil
    
    init() {
        if let savedRate = UserDefaults.standard.object(forKey: DefaultsKeys.rate) as? Double {
            self.exchangeRate = savedRate
        }
        if let savedDateInterval = UserDefaults.standard.object(forKey: DefaultsKeys.lastUpdated) as? TimeInterval {
            self.lastUpdated = Date(timeIntervalSince1970: savedDateInterval)
        }
        Task { [weak self] in
            await self?.refreshExchangeRateIfNeeded()
        }
    }
    
    @MainActor
    func refreshExchangeRateIfNeeded() async {
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)
        if let last = lastUpdated, last >= startOfToday {
            // Already refreshed sometime today
            return
        }
        await fetchExchangeRate()
    }
    
    func fetchExchangeRate() async {
        
        guard let url = URL(string: "https://api.apilayer.com/exchangerates_data/latest?symbols=INR&base=USD") else { return }
        isLoadingRate = true
        defer { isLoadingRate = false }
        do {
            let decoded: RateResponse = try await NetworkManager.shared.getResponse(
                from: url,
                headers: ["apikey": "cualLc86jPPqWwxNk6H1KRwHPqI9doH6"]
            )
            if let rate = decoded.rates?["INR"] {
                let now = Date()
                exchangeRate = rate
                lastUpdated = now
                persistRate(rate, at: now)
            }
        } catch {
            print("⚠️ Error fetching rate:", error)
        }
    }
    
    private func persistRate(_ rate: Double, at date: Date) {
        UserDefaults.standard.set(rate, forKey: DefaultsKeys.rate)
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: DefaultsKeys.lastUpdated)
    }
    
    func groupedByCategory(_ assets: [Asset]) -> [(Asset.CategoryType, Double)] {
        let dict = Dictionary(grouping: assets) { $0.category }
        return dict.map { (key, group) in
            let total = totalInUSD(group, exchangeRate: exchangeRate)
            return (key ?? .others, total)
        }.sorted { $0.1 > $1.1 }
    }
    
    func getFooterData(_ assets: [Asset]) -> FooterModel {
        return FooterModel(
            usdValue: totalInUSD(assets, exchangeRate: exchangeRate),
            inrValue: totalInINR(assets, exchangeRate: exchangeRate),
            lastUpdated: lastUpdated,
            exchangeRate: exchangeRate
        )
    }
}

struct RateResponse: Codable {
    let base, date: String?
    let rates: [String: Double]?
    let success: Bool?
    let timestamp: Int?
}
