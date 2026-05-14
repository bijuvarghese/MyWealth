import SwiftUI

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
                    .foregroundStyle(.accent)
            }
        }
    }
}

enum OnboardingStep: Int, CaseIterable {
    case baseCurrency
    case displayCurrencies

    var title: String {
        switch self {
        case .baseCurrency:
            "Choose Base Currency"
        case .displayCurrencies:
            "Choose Display Currencies"
        }
    }
}

struct OnboardingView: View {
    @Bindable var settings: AppSettings

    @State private var currentStep: OnboardingStep = .baseCurrency
    @State private var baseCurrency: Asset.CurrencyType = .usd
    @State private var displayCurrencies: [Asset.CurrencyType] = [.usd, .inr]
    @State private var didLoadInitialValues = false

    var body: some View {
        NavigationStack {
            VStack {
                progressHeader

                switch currentStep {
                case .baseCurrency:
                    OnboardingBaseCurrencyStepView(baseCurrency: $baseCurrency)

                case .displayCurrencies:
                    OnboardingDisplayCurrencyStepView(
                        displayCurrencies: $displayCurrencies,
                        baseCurrency: baseCurrency
                    )
                }
            }
            .navigationTitle(currentStep.title)
            .safeAreaInset(edge: .bottom) {
                bottomButton
            }
        }
        .onAppear {
            guard !didLoadInitialValues else { return }

            baseCurrency = settings.baseCurrency
            displayCurrencies = settings.totalCurrencies

            if !displayCurrencies.contains(baseCurrency) {
                displayCurrencies.insert(baseCurrency, at: 0)
            }

            didLoadInitialValues = true
        }
        .onChange(of: baseCurrency) { _, newValue in
            if !displayCurrencies.contains(newValue) {
                displayCurrencies.insert(newValue, at: 0)
            }
        }
    }

    private var progressHeader: some View {
        HStack {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color.gray.opacity(0.25))
                    .frame(height: 6)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var bottomButton: some View {
        Button {
            handlePrimaryAction()
        } label: {
            Text(currentStep == .displayCurrencies ? "Finish Setup" : "Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .frame(height: 44)
        .buttonStyle(.borderedProminent)
        .disabled(currentStep == .displayCurrencies && displayCurrencies.isEmpty)
        .padding()
        .background(.regularMaterial)
    }

    private func handlePrimaryAction() {
        switch currentStep {
        case .baseCurrency:
            currentStep = .displayCurrencies

        case .displayCurrencies:
            settings.completeOnboarding(
                baseCurrency: baseCurrency,
                displayCurrencies: displayCurrencies
            )
        }
    }
}

private struct OnboardingBaseCurrencyStepView: View {
    @Binding var baseCurrency: Asset.CurrencyType

    var body: some View {
        Form {
            Section {
                Text("Your base currency is used to calculate your total wealth and fetch exchange rates for all your assets.")
                    .foregroundStyle(.primary)

                NavigationLink {
                    OnboardingCurrencyPickerView(selection: $baseCurrency)
                } label: {
                    LabeledContent("Base Currency") {
                        CurrencySummaryView(currency: baseCurrency)
                    }
                }
            } header: {
                Text("Required")
            } footer: {
                Text("You can change this later from Settings.")
            }
        }
    }
}

private struct OnboardingDisplayCurrencyStepView: View {
    @Binding var displayCurrencies: [Asset.CurrencyType]
    let baseCurrency: Asset.CurrencyType

    var body: some View {
        Form {
            Section {
                Text("Display currencies help you see your total wealth converted into different currencies around the world.")
                    .foregroundStyle(.primary)

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
            } header: {
                Text("Optional but Recommended")
            } footer: {
                Text("Your base currency is always included.")
            }
        }
    }
}
