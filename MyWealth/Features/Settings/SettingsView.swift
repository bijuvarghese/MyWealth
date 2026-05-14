import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                Section("Features") {
                    NavigationLink(destination: ReminderSettingsView()) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.blue)
                            Text("Reminders")
                        }
                    }
                }

                Section("Totals") {
                    NavigationLink {
                        BaseCurrencySelectionView(settings: settings)
                    } label: {
                        LabeledContent("Base Currency") {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(settings.baseCurrency.rawValue)
                                    .foregroundStyle(.primary)
                                Text(settings.baseCurrency.name)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }

                    NavigationLink {
                        TotalCurrencySelectionView(settings: settings)
                    } label: {
                        LabeledContent("Display Currencies") {
                            Text(settings.totalCurrencies.map(\.rawValue).joined(separator: ", "))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct BaseCurrencySelectionView: View {
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
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
        .navigationTitle("Base Currency")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }

    private func currencyButton(for currency: Asset.CurrencyType) -> some View {
        Button {
            settings.setBaseCurrency(currency)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(currency.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(currency.name)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                if settings.baseCurrency == currency {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.accent)
                }
            }
        }
    }
}

private struct TotalCurrencySelectionView: View {
    @Bindable var settings: AppSettings
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
    }

    private func currencyButton(for currency: Asset.CurrencyType) -> some View {
        Button {
            settings.toggleTotalCurrency(currency)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(currency.rawValue)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(currency.name)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                if settings.totalCurrencies.contains(currency) {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.accent)
                }
            }
        }
    }
}
