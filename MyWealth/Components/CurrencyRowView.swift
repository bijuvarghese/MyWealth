import SwiftUI

struct CurrencyRowView: View {
    let currency: Asset.CurrencyType
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(currency.rawValue)
                    .font(WealthMapDesignTokens.Typography.headline)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                Text(currency.name)
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.inactive)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(WealthMapDesignTokens.Typography.bodySemibold)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
            }
        }
    }
}

struct DisplayCurrencyArrangementView: View {
    @Binding var currencies: [Asset.CurrencyType]
    let requiredCurrency: Asset.CurrencyType

    private var arrangedCurrencies: [Asset.CurrencyType] {
        currencies.filter { $0 != requiredCurrency && $0 != .none }
    }

    var body: some View {
        List {
            Section("Base Currency") {
                CurrencyRowView(currency: requiredCurrency, isSelected: true)
            }

            Section("Display Order") {
                ForEach(arrangedCurrencies) { currency in
                    CurrencyRowView(currency: currency, isSelected: true)
                }
                .onMove(perform: moveCurrencies)
            }
        }
        .navigationTitle("Arrange Currencies")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .onAppear {
            currencies = normalizedCurrencies(currencies)
        }
    }

    private func moveCurrencies(fromOffsets source: IndexSet, toOffset destination: Int) {
        var reorderedCurrencies = arrangedCurrencies
        let movingCurrencies = source
            .sorted()
            .map { reorderedCurrencies[$0] }

        for index in source.sorted(by: >) {
            reorderedCurrencies.remove(at: index)
        }

        let removedBeforeDestination = source.filter { $0 < destination }.count
        let adjustedDestination = destination - removedBeforeDestination
        let insertionIndex = min(max(adjustedDestination, 0), reorderedCurrencies.count)

        reorderedCurrencies.insert(contentsOf: movingCurrencies, at: insertionIndex)
        currencies = normalizedCurrencies(reorderedCurrencies)
    }

    private func normalizedCurrencies(_ selectedCurrencies: [Asset.CurrencyType]) -> [Asset.CurrencyType] {
        ([requiredCurrency] + selectedCurrencies).reduce(into: [Asset.CurrencyType]()) { result, currency in
            guard currency != .none, !result.contains(currency) else {
                return
            }
            result.append(currency)
        }
    }
}
