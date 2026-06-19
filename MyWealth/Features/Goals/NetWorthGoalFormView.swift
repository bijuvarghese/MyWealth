import SwiftUI
import SwiftData

struct NetWorthGoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let goal: NetWorthGoal?
    let assets: [Asset]
    let liabilities: [Liability]
    let exchangeRates: [String: Double]
    let ratesAreStale: Bool
    let useCompactFormatting: Bool
    @State private var amountText: String
    @State private var currency: Asset.CurrencyType
    @State private var targetDate: Date
    @State private var errorMessage: String?
    @State private var isConfirmingDelete = false

    init(
        goal: NetWorthGoal?,
        defaultCurrency: Asset.CurrencyType,
        assets: [Asset],
        liabilities: [Liability],
        exchangeRates: [String: Double],
        ratesAreStale: Bool,
        useCompactFormatting: Bool
    ) {
        self.goal = goal
        self.assets = assets
        self.liabilities = liabilities
        self.exchangeRates = exchangeRates
        self.ratesAreStale = ratesAreStale
        self.useCompactFormatting = useCompactFormatting
        _amountText = State(initialValue: goal.map { String($0.displayTargetAmount) } ?? "")
        _currency = State(initialValue: goal?.displayCurrency ?? defaultCurrency)
        _targetDate = State(initialValue: goal?.displayTargetDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date())
    }

    private var parsedAmount: Double? { Double(amountText) }
    private var draft: NetWorthGoalDraft? {
        guard let parsedAmount else { return nil }
        return NetWorthGoalDraft(
            targetAmount: parsedAmount,
            currency: currency,
            targetDate: targetDate
        )
    }
    private var validationIssues: Set<NetWorthGoalValidationIssue> {
        draft?.validationIssues() ?? [.targetAmount]
    }
    private var canSave: Bool { validationIssues.isEmpty }
    private var currentValue: NetWorthGoalCurrentValue {
        NetWorthGoalCalculator().currentValue(
            currency: currency,
            assets: assets,
            liabilities: liabilities,
            exchangeRates: exchangeRates,
            ratesAreStale: ratesAreStale
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Target") {
                    TextField("Target Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityHint("Enter an amount greater than zero")
                    if validationIssues.contains(.targetAmount), !amountText.isEmpty {
                        validationText("Enter an amount greater than zero.")
                    }

                    NavigationLink {
                        CurrencySelectionView(selection: $currency)
                    } label: {
                        LabeledContent("Currency") {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(currency.rawValue)
                                Text(currency.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    DatePicker(
                        "Target Date",
                        selection: $targetDate,
                        in: Calendar.current.startOfDay(for: Date())...,
                        displayedComponents: .date
                    )
                    if validationIssues.contains(.targetDate) {
                        validationText("Choose today or a future date.")
                    }
                }

                Section("Current Net Worth") {
                    LabeledContent("Portfolio") {
                        Text(currentValueText)
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(currentValue.amount == nil ? .secondary : .primary)
                    }
                    if let currentValueNote {
                        Label(currentValueNote.text, systemImage: currentValueNote.symbol)
                            .font(.caption)
                            .foregroundStyle(currentValueNote.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Section {
                    Text("Projections are indicative and use your recorded net worth history. They are not financial advice or a guarantee.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if goal != nil {
                    Section {
                        Button("Delete Goal", role: .destructive) {
                            isConfirmingDelete = true
                        }
                    }
                }
            }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "Delete Net Worth Goal?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete Goal", role: .destructive) { deleteGoal() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes only your goal. Assets, liabilities, and history stay unchanged.")
            }
            .alert("Unable to Save Goal", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func validationText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.red)
            .accessibilityLabel("Validation error: \(text)")
    }

    private var currentValueText: String {
        guard let amount = currentValue.amount else { return "Unavailable" }
        if useCompactFormatting {
            return amount.formatted(
                .currency(code: currency.rawValue)
                    .notation(.compactName)
                    .precision(.fractionLength(0...1))
            )
        }
        return amount.formatted(
            .currency(code: currency.rawValue)
                .precision(.fractionLength(0...2))
        )
    }

    private var currentValueNote: (text: String, symbol: String, color: Color)? {
        guard currentValue.amount != nil else {
            if assets.isEmpty && liabilities.isEmpty {
                return ("Add assets or liabilities to calculate your current net worth.", "info.circle", .secondary)
            }
            if case .unavailable(let missingCodes) = currentValue.rateState {
                let suffix = missingCodes.isEmpty ? "" : " Missing: \(missingCodes.joined(separator: ", "))."
                return ("Current net worth cannot be converted to \(currency.rawValue).\(suffix)", "exclamationmark.triangle", .orange)
            }
            return ("Current net worth is unavailable.", "exclamationmark.triangle", .orange)
        }
        if currentValue.rateState == .stale {
            return ("Calculated using saved exchange rates.", "clock.badge.exclamationmark", .orange)
        }
        return nil
    }

    private func save() {
        guard let draft else { return }
        do {
            _ = try NetWorthGoalStore.upsert(draft, in: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteGoal() {
        do {
            try NetWorthGoalStore.deleteAll(in: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
