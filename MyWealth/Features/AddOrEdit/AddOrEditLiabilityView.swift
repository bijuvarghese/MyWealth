import SwiftUI
import SwiftData

struct AddOrEditLiabilityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var liability: Liability?

    @State private var name = ""
    @State private var amount = ""
    @State private var currency: Asset.CurrencyType = .usd
    @State private var category: Liability.CategoryType = .mortgage

    private var isEditing: Bool { liability != nil }
    private var amountValue: Double? { Double(amount) }

    init(liability: Liability? = nil) {
        self.liability = liability
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Debt Name", text: $name)

                TextField("Balance", text: $amount)
                    .keyboardType(.decimalPad)

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

                Picker("Type", selection: $category) {
                    ForEach(Liability.CategoryType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let liability {
                                modelContext.delete(liability)
                                dismiss()
                            }
                        } label: {
                            Text("Delete Debt")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Debt" : "Add Debt")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") {
                        guard let value = amountValue, value > 0, !name.isEmpty else {
                            return
                        }

                        if let liability {
                            liability.name = name
                            liability.amount = value
                            liability.currency = currency
                            liability.category = category
                            liability.lastUpdated = Date()
                        } else {
                            let newLiability = Liability(
                                name: name,
                                amount: value,
                                currency: currency,
                                category: category,
                                lastUpdated: Date()
                            )
                            modelContext.insert(newLiability)
                        }

                        dismiss()
                    }
                    .disabled(name.isEmpty || (amountValue ?? 0) <= 0)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            if let liability {
                name = liability.displayName
                amount = String(liability.displayAmount)
                currency = liability.currency ?? .usd
                category = liability.displayCategory
            }
        }
    }
}
