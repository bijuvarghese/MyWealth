//
//  AddAssetView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//


import SwiftUI
import SwiftData
import Charts

struct AddAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var amount = ""
    @State private var currency: Asset.CurrencyType = .usd
    @State private var category: Asset.CategoryType = .others
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Asset Name", text: $name)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                
                Picker("Currency", selection: $currency) {
                    ForEach(Asset.CurrencyType.allCases) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                Picker("Category", selection: $category) {
                    ForEach(Asset.CategoryType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
            }
            .navigationTitle("Add Asset")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value = Double(amount), !name.isEmpty else { return }
                        let newAsset = Asset(name: name, amount: value, currency: currency, category: category, lastUpdated: Date())
                        modelContext.insert(newAsset)
                        dismiss()
                    }
                    .disabled(name.isEmpty || Double(amount) == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
