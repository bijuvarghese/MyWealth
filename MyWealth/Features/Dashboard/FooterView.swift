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
        VStack {
            if let updated = viewModel.lastUpdated {
                Text("Last updated: \(updated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity)
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
