//
//  FooterView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//

import SwiftUI

struct FooterView: View {
    
    let viewModel: FooterViewModel
    
    init(model: FooterModel) {
        self.viewModel = FooterViewModel(model: model)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("💵 Total in USD:")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.usdValue, format: .currency(code: "USD"))")
                    .font(.title2)
            }
            HStack {
                Text("🇮🇳 Total in INR:")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.inrValue, format: .currency(code: "INR"))")
                    .font(.title2)
            }
            if let updated = viewModel.lastUpdated {
                Text("Last updated: \(updated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 24)
        .background(.launch)
    }
    
}

class FooterViewModel {
    let model: FooterModel
    
    init(model: FooterModel) {
        self.model = model
    }
    
    var usdValue: Double { model.usdValue }
    var inrValue: Double { model.inrValue }
    var lastUpdated: Date? { model.lastUpdated }
}

struct FooterModel {
    let usdValue: Double
    let inrValue: Double
    let lastUpdated: Date?
    
    init(usdValue: Double, inrValue: Double, lastUpdated: Date?) {
        self.usdValue = usdValue
        self.inrValue = inrValue
        self.lastUpdated = lastUpdated
    }
}
