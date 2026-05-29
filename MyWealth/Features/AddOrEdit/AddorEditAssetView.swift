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

    // MARK: - Common state
    @State private var name = ""
    @State private var currency: Asset.CurrencyType = .usd
    @State private var category: Asset.CategoryType = .others
    @State private var includeInPortfolio = true

    // MARK: - Non-metal state
    @State private var amount = ""

    // MARK: - Metal state
    @State private var metalWeight = ""
    @State private var weightUnit: WeightUnit = .troyOz
    @State private var metalViewModel = MetalPricesViewModel()

    // MARK: - Helpers

    var isEditing: Bool { asset != nil }

    private var currentMetal: PreciousMetalSelectionView.MetalOption? {
        guard let metalCurrency = category.metalCurrency else { return nil }
        return PreciousMetalSelectionView.metals.first { $0.currency == metalCurrency }
    }

    /// Weight in troy oz derived from the user's input (nil when input is invalid).
    private var weightInTroyOz: Double? {
        guard let w = Double(metalWeight), w > 0 else { return nil }
        return w * weightUnit.troyOzPerUnit
    }

    /// Estimated market value in USD, computed from the live metal price.
    private var estimatedValueUSD: Double? {
        guard let troyOz = weightInTroyOz,
              let metalSymbol = category.metalCurrency?.rawValue,
              let metalRate = metalViewModel.metalRates[metalSymbol],
              metalRate > 0 else { return nil }
        // API returns "units of metal per 1 USD", so price per troy oz = 1 / metalRate
        return troyOz / metalRate
    }

    /// True when the Save/Update button should be enabled.
    private var canSave: Bool {
        guard !name.isEmpty else { return false }
        if category.isPreciousMetal {
            return Double(metalWeight) != nil
        }
        return Double(amount) != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                if category.isPreciousMetal {
                    metalInputSection
                    if let metal = currentMetal {
                        metalInfoSection(metal: metal)
                    }
                } else {
                    amountSection
                    currencySection
                }
                categorySection
                portfolioSection
            }
            .navigationTitle(isEditing ? "Edit Asset" : "Add Asset")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") { save() }
                        .disabled(!canSave)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: category) { _, newCategory in
                if let metalCurrency = newCategory.metalCurrency {
                    currency = metalCurrency
                } else if currency.isPreciousMetal {
                    currency = .usd
                }
            }
            .onChange(of: weightUnit) { _, _ in
                // Re-express the stored troy oz in the newly chosen unit when editing.
                if isEditing, let asset, let storedTroyOz = asset.amount, storedTroyOz > 0 {
                    metalWeight = formatWeight(storedTroyOz, unit: weightUnit)
                }
            }
        }
        .onAppear {
            prefillIfEditing()
            Task { await metalViewModel.refreshIfNeeded() }
        }
    }

    // MARK: - Form sections

    private var nameSection: some View {
        TextField("Asset Name", text: $name)
    }

    private var amountSection: some View {
        TextField("Amount", text: $amount)
            .keyboardType(.decimalPad)
    }

    private var currencySection: some View {
        NavigationLink {
            CurrencySelectionView(selection: $currency)
        } label: {
            LabeledContent("Currency") {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currency.rawValue)
                        .foregroundStyle(.primary)
                    Text(currency.name)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
        }
    }

    @ViewBuilder
    private var metalInputSection: some View {
        Section {
            HStack(spacing: 10) {
                TextField("Weight", text: $metalWeight)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity)

                Divider()

                Picker("Unit", selection: $weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }

            // Estimated value row (read-only)
            LabeledContent("Est. Value (USD)") {
                if metalViewModel.isLoading {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text("Loading price…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let value = estimatedValueUSD {
                    Text(value, format: .currency(code: "USD"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                } else if metalViewModel.metalRates.isEmpty {
                    Text("Price unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Enter weight above")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listRowBackground(estimatedValueUSD != nil ? Color.yellow.opacity(0.12) : nil)
        } header: {
            Text("Weight")
        } footer: {
            Text("Amount is stored in troy oz. Estimated value uses live metal prices (USD).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func metalInfoSection(metal: PreciousMetalSelectionView.MetalOption) -> some View {
        Section("Metal") {
            LabeledContent("Type") {
                HStack(spacing: 8) {
                    Circle()
                        .fill(metal.color)
                        .frame(width: 10, height: 10)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(metal.name)
                            .foregroundStyle(.primary)
                        Text("\(metal.symbol) · troy oz")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }

            if let rate = metalViewModel.metalRates[metal.symbol], rate > 0 {
                LabeledContent("Spot Price") {
                    Text(1.0 / rate, format: .currency(code: "USD"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var categorySection: some View {
        Picker("Category", selection: $category) {
            ForEach(Asset.CategoryType.allCases) { type in
                Label(type.rawValue, systemImage: type.icon)
                    .tag(type)
            }
        }
    }

    private var portfolioSection: some View {
        Section {
            Toggle(isOn: $includeInPortfolio) {
                Label("Include in Portfolio", systemImage: "chart.pie.fill")
            }
            .tint(.accentColor)
        } footer: {
            Text("Ignored assets stay in your list and history, but are left out of portfolio totals unless Settings includes ignored assets.")
        }
    }

    // MARK: - Save

    private func save() {
        let valueToStore: Double
        let unitToStore: WeightUnit?

        if category.isPreciousMetal {
            guard let troyOz = weightInTroyOz else { return }
            valueToStore = troyOz
            unitToStore = weightUnit
        } else {
            guard let monetary = Double(amount) else { return }
            valueToStore = monetary
            unitToStore = nil
        }

        if let existing = asset {
            existing.name = name
            existing.amount = valueToStore
            existing.currency = currency
            existing.category = category
            existing.weightUnit = unitToStore
            existing.isIncludedInPortfolio = includeInPortfolio
            existing.lastUpdated = Date()
        } else {
            let newAsset = Asset(
                name: name,
                amount: valueToStore,
                currency: currency,
                category: category,
                lastUpdated: Date(),
                weightUnit: unitToStore,
                isIncludedInPortfolio: includeInPortfolio
            )
            modelContext.insert(newAsset)
        }
        dismiss()
    }

    // MARK: - Edit prefill

    private func prefillIfEditing() {
        guard let asset else { return }
        name = asset.displayName
        currency = asset.currency ?? .usd
        category = asset.displayCategory
        includeInPortfolio = asset.participatesInPortfolioCalculations

        if asset.displayCategory.isPreciousMetal {
            let unit = asset.weightUnit ?? .troyOz
            weightUnit = unit
            metalWeight = formatWeight(asset.displayAmount, unit: unit)
        } else {
            amount = String(asset.displayAmount)
        }
    }

    // MARK: - Formatting

    /// Converts `troyOz` into `unit`, formatted without unnecessary decimals.
    private func formatWeight(_ troyOz: Double, unit: WeightUnit) -> String {
        let value = troyOz / unit.troyOzPerUnit
        // %g removes trailing zeros and uses fixed notation for typical weights.
        return unsafe String(format: "%g", value)
    }
}
