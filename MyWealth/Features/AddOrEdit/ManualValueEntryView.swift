//
//  ManualValueEntryView.swift
//  MyWealth
//
//  Sheet for logging a manual value update on a non-market asset (real estate,
//  cars, personal property, etc.). The user enters the appraised / estimated
//  value, picks the date the valuation applies to, and optionally adds a note
//  such as "Re-appraised by ABC Valuers".
//

import SwiftUI
import SwiftData

struct ManualValueEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let asset: Asset

    @State private var amountText: String
    @State private var selectedDate: Date = Date()
    @State private var note: String = ""

    init(asset: Asset) {
        self.asset = asset
        // Pre-fill with the asset's current value so the user only needs to
        // change it if the new appraisal differs.
        let current = asset.displayAmount
        _amountText = State(initialValue: current > 0 ? formatAmount(current) : "")
    }

    // MARK: - Computed

    private var parsedAmount: Double? {
        guard let value = Double(amountText), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool { parsedAmount != nil }

    private var currencyCode: String {
        let code = asset.displayCurrency.rawValue
        return code.isEmpty ? "USD" : code
    }

    private var trimmedNote: String? {
        let t = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                valueSection
                dateSection
                noteSection
                previewSection
            }
            .navigationTitle("Log Value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Form sections

    private var valueSection: some View {
        Section {
            HStack {
                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)

                Divider()
                    .frame(height: 22)

                Text(currencyCode)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                    .fixedSize()
            }
        } header: {
            Text("Appraised Value")
        } footer: {
            Text("Enter the estimated or officially appraised value for this asset.")
                .font(WealthMapDesignTokens.Typography.caption)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
        }
    }

    private var dateSection: some View {
        Section("Valuation Date") {
            DatePicker(
                "Date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
        }
    }

    private var noteSection: some View {
        Section {
            TextField(
                "e.g. Re-appraised by ABC Valuers",
                text: $note,
                axis: .vertical
            )
            .lineLimit(2...4)
        } header: {
            Text("Note (Optional)")
        } footer: {
            Text("Add context about this valuation — who assessed it, why the value changed, etc.")
                .font(WealthMapDesignTokens.Typography.caption)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
        }
    }

    @ViewBuilder
    private var previewSection: some View {
        if let amount = parsedAmount {
            Section("Preview") {
                HStack(spacing: 12) {
                    Image(systemName: "pencil.and.list.clipboard")
                        .font(WealthMapDesignTokens.Typography.subheadline)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(asset.displayName)
                            .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                            .lineLimit(1)
                        Text(selectedDate, format: .dateTime.month(.abbreviated).day().year())
                            .font(WealthMapDesignTokens.Typography.caption)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        if let n = trimmedNote {
                            Text(n)
                                .font(WealthMapDesignTokens.Typography.caption)
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    Text(amount, format: .currency(code: currencyCode))
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        guard let amount = parsedAmount else { return }

        let snapshot = AssetValueSnapshot(
            assetIdentifier: asset.stableHistoryIdentifier,
            assetName: asset.displayName,
            amount: amount,
            currencyCode: asset.displayCurrency.rawValue,
            categoryName: asset.displayCategory.rawValue,
            recordedAt: selectedDate,
            isManual: true,
            note: trimmedNote
        )
        modelContext.insert(snapshot)
        dismiss()
    }
}

// MARK: - Helpers

/// Formats a Double for display in the amount text field, stripping unnecessary
/// decimal zeros (e.g. 8500000.0 → "8500000", 8500000.5 → "8500000.5").
private func formatAmount(_ value: Double) -> String {
    if value.truncatingRemainder(dividingBy: 1) == 0 {
        return String(Int(value))
    }
    return String(value)
}
