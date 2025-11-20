//
//  AddorEditAssetView.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//

import SwiftUI
import SwiftData
import Charts

struct AddorEditAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // If provided, we are editing this asset; otherwise we're adding a new one
    var asset: Asset?
    
    @State private var name = ""
    @State private var amount = ""
    @State private var currency: Asset.CurrencyType = .usd
    @State private var category: Asset.CategoryType = .others
    
    var isEditing: Bool { asset != nil }
    
    init(asset: Asset? = nil) {
        self.asset = asset
    }
    
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
                
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let assetToDelete = asset {
                                modelContext.delete(assetToDelete)
                                dismiss()
                            }
                        } label: {
                            Text("Delete Asset")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Asset" : "Add Asset")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") {
                        guard let value = Double(amount), !name.isEmpty else { return }
                        if let existing = asset {
                            // Update existing asset
                            existing.name = name
                            existing.amount = value
                            existing.currency = currency
                            existing.category = category
                            existing.lastUpdated = Date()
                        } else {
                            // Create new asset
                            let newAsset = Asset(name: name, amount: value, currency: currency, category: category, lastUpdated: Date())
                            modelContext.insert(newAsset)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty || Double(amount) == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            // Prefill fields when editing
            if let asset {
                name = asset.name ?? ""
                amount = String(asset.amount ?? 0)
                currency = asset.currency ?? .none
                category = asset.category ?? .others
            }
        }
    }
}
