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
            ForEach(viewModel.totals) { total in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total in \(total.currency.rawValue)")
                            .font(.headline)
                        Text(total.currency.name)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Text(total.amount, format: .currency(code: total.currency.rawValue))
                        .font(.title2)
                }
            }
            Text("Base: \(viewModel.baseCurrency.rawValue) - \(viewModel.baseCurrency.name)")
                .font(.caption2)
                .foregroundStyle(.gray)
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
    
    var totals: [ConvertedCurrencyTotal] { model.totals }
    var baseCurrency: Asset.CurrencyType { model.baseCurrency }
    var lastUpdated: Date? { model.lastUpdated }
    var rates: [String: Double] { model.rates }
}

struct FooterModel {
    let totals: [ConvertedCurrencyTotal]
    let baseCurrency: Asset.CurrencyType
    let lastUpdated: Date?
    let rates: [String: Double]
    
}
