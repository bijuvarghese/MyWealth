import SwiftUI

struct OnboardingDisplayCurrencyPickerView: View {
    @Binding var selections: [Asset.CurrencyType]
    let requiredCurrency: Asset.CurrencyType
    @State private var searchText = ""

    private let commonCurrencies: [Asset.CurrencyType] = [
        .usd,
        .inr,
        .eur,
        .gbp,
        .cad,
        .aud
    ]

    private var filteredCurrencies: [Asset.CurrencyType] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return Asset.CurrencyType.selectableCases
        }

        return Asset.CurrencyType.selectableCases.filter { currency in
            currency.rawValue.localizedCaseInsensitiveContains(query) ||
            currency.name.localizedCaseInsensitiveContains(query)
        }
    }

    private var groupedCurrencies: [(String, [Asset.CurrencyType])] {
        let currencies = searchText.isEmpty
            ? filteredCurrencies.filter { !commonCurrencies.contains($0) }
            : filteredCurrencies

        let grouped = Dictionary(grouping: currencies) { currency in
            String(currency.rawValue.prefix(1))
        }

        return grouped
            .map { ($0.key, $0.value.sorted { $0.rawValue < $1.rawValue }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        List {
            if searchText.isEmpty {
                Section("Common") {
                    ForEach(commonCurrencies) { currency in
                        currencyButton(for: currency)
                    }
                }
            }

            ForEach(groupedCurrencies, id: \.0) { letter, currencies in
                Section(letter) {
                    ForEach(currencies) { currency in
                        currencyButton(for: currency)
                    }
                }
            }
        }
        .navigationTitle("Display Currencies")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .scrollContentBackground(.hidden)
        .background {
            RadialDotBackground(dotRadius: 1, spacing: 20)
                .ignoresSafeArea(.all)
        }
        .onAppear {
            if !selections.contains(requiredCurrency) {
                selections.insert(requiredCurrency, at: 0)
            }
        }
    }

    private func currencyButton(for currency: Asset.CurrencyType) -> some View {
        Button {
            toggle(currency)
        } label: {
            CurrencyRowView(currency: currency, isSelected: selections.contains(currency))
        }
        .disabled(currency == requiredCurrency)
    }

    private func toggle(_ currency: Asset.CurrencyType) {
        if selections.contains(currency) {
            if selections.count > 1 && currency != requiredCurrency {
                selections.removeAll { $0 == currency }
            }
        } else {
            selections.append(currency)
            selections.sort { $0.rawValue < $1.rawValue }
        }
    }
}
