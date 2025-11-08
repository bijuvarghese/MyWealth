//
//  AssetChartsView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//


import SwiftUI
import SwiftData
import Charts

struct AssetChartsView: View {
    let assets: [Asset]
    let viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !assets.isEmpty {
                Text("Category Breakdown")
                    .font(.headline)
                
                // Bar chart - category distribution
                Chart(viewModel.groupedByCategory(assets), id: \.0) { category, value in
                    BarMark(
                        x: .value("Category", category.rawValue),
                        y: .value("Value (USD)", value)
                    )
                    .foregroundStyle(by: .value("Category", category.rawValue))
                }
                .frame(height: 200)
                .chartLegend(.visible)
                
                // Pie chart - overall USD vs INR
                let usdValue = assets.filter { $0.currency == .usd }.reduce(0) { $0 + ($1.amount ?? 0) }
                let inrValue = assets.filter { $0.currency == .inr }.reduce(0) { $0 + ($1.amount ?? 0)  / viewModel.exchangeRate }
                
                Chart {
                    SectorMark(
                        angle: .value("USD", usdValue),
                        innerRadius: .ratio(0.6)
                    )
                    .foregroundStyle(.blue)
                    SectorMark(
                        angle: .value("INR", inrValue),
                        innerRadius: .ratio(0.6)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 200)
                .chartLegend(.hidden)
            }
        }
        .padding(.vertical)
    }
}
