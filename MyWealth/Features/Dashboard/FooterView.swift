//
//  FooterView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//

import SwiftUI

struct FooterView: View {
    
    let usdValue: Double
    let inrValue: Double
    let lastUpdated: Date?
    
    var body: some View {
        VStack(spacing: 6) {
            Text("💵 Total in USD: \(usdValue, format: .currency(code: "USD"))")
                .font(.headline)
            Text("🇮🇳 Total in INR: \(inrValue, format: .currency(code: "INR"))")
                .foregroundStyle(.secondary)
            
            if let updated = lastUpdated {
                Text("Last updated: \(updated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    
}
