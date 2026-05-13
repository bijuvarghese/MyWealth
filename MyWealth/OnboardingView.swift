import SwiftUI

struct OnboardingView: View {
    @Bindable var settings: AppSettings
    @State private var baseCurrency: Asset.CurrencyType = .usd
    @State private var displayCurrencies: [Asset.CurrencyType] = [.usd, .inr]
    @State private var didLoadInitialValues = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        OnboardingCurrencyPickerView(selection: $baseCurrency)
                    } label: {
                        LabeledContent("Default Currency") {
                            CurrencySummaryView(currency: baseCurrency)
                        }
                    }

                    NavigationLink {
                        OnboardingDisplayCurrencyPickerView(
                            selections: $displayCurrencies,
                            requiredCurrency: baseCurrency
                        )
                    } label: {
                        LabeledContent("Display Currencies") {
                            Text(displayCurrencies.map(\.rawValue).joined(separator: ", "))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Set Up Wealthy")
            .safeAreaInset(edge: .bottom) {
                Button {
                    settings.completeOnboarding(
                        baseCurrency: baseCurrency,
                        displayCurrencies: displayCurrencies
                    )
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(displayCurrencies.isEmpty)
                .padding()
                .background(.regularMaterial)
            }
        }
        .onAppear {
            guard !didLoadInitialValues else {
                return
            }
            baseCurrency = settings.baseCurrency
            displayCurrencies = settings.totalCurrencies
            didLoadInitialValues = true
        }
        .onChange(of: baseCurrency) { _, newValue in
            if !displayCurrencies.contains(newValue) {
                displayCurrencies.insert(newValue, at: 0)
            }
        }
    }
}

private struct CurrencySummaryView: View {
    let currency: Asset.CurrencyType

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(currency.rawValue)
                .foregroundStyle(.primary)
            Text(currency.name)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

private struct OnboardingCurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: Asset.CurrencyType
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
        .navigationTitle("Default Currency")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }

    private func currencyButton(for currency: Asset.CurrencyType) -> some View {
        Button {
            selection = currency
            dismiss()
        } label: {
            CurrencyRowView(currency: currency, isSelected: selection == currency)
        }
    }
}

private struct OnboardingDisplayCurrencyPickerView: View {
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

private struct CurrencyRowView: View {
    let currency: Asset.CurrencyType
    let isSelected: Bool

    var body: some View {
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

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.launch)
            }
        }
    }
}

#Preview {
    OnboardingView(settings: AppSettings(userDefaults: .standard))
}
