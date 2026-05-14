import SwiftUI

struct OnboardingView: View {
    @Bindable var settings: AppSettings

    @State private var currentStep: OnboardingStep = .baseCurrency
    @State private var baseCurrency: Asset.CurrencyType = .usd
    @State private var displayCurrencies: [Asset.CurrencyType] = [.usd, .inr]
    @State private var remindersEnabled = false
    @State private var reminderType: ReminderType = .reviewPortfolio
    @State private var reminderFrequency: ReminderFrequency = .weekly
    @State private var didLoadInitialValues = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                progressHeader
                switch currentStep {
                case .baseCurrency:
                    OnboardingBaseCurrencyStepView(baseCurrency: $baseCurrency)
                case .displayCurrencies:
                    OnboardingDisplayCurrencyStepView(
                        displayCurrencies: $displayCurrencies,
                        baseCurrency: baseCurrency
                    )
                case .reminders:
                    OnboardingReminderStepView(
                        remindersEnabled: $remindersEnabled,
                        reminderType: $reminderType,
                        reminderFrequency: $reminderFrequency
                    )
                }
            }
            .navigationTitle("Setup Wealth Map")
            .safeAreaInset(edge: .bottom) {
                bottomButton
            }
        }
        .onAppear {
            guard !didLoadInitialValues else { return }

            baseCurrency = settings.baseCurrency
            displayCurrencies = settings.totalCurrencies
            currentStep = settings.firstMissingOnboardingStep()

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
            Text(currentStep == .reminders ? "Finish Setup" : "Continue")
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
            currentStep = .reminders
            
        case .reminders:
            if remindersEnabled {
                ReminderManager.shared.enableReminders(
                    frequency: reminderFrequency,
                    type: reminderType
                )
            } else {
                ReminderManager.shared.disableReminders()
            }
            
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
                NavigationLink {
                    OnboardingCurrencyPickerView(selection: $baseCurrency)
                } label: {
                    LabeledContent("Base Currency*") {
                        CurrencySummaryView(currency: baseCurrency)
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Select your base currency", systemImage: "globe")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)

                        Text("Your base currency is the foundation of your Wealth Map.")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("It’s used to calculate your total wealth and convert assets using current exchange rates.")
                            .font(.body)
                            .foregroundStyle(.primary)

                        Text("You can update this later in Settings.")
                            .font(.footnote)
                            .foregroundStyle(.primary)
                }
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
                NavigationLink {
                    OnboardingDisplayCurrencyPickerView(
                        selections: $displayCurrencies,
                        requiredCurrency: baseCurrency
                    )
                } label: {
                    LabeledContent("Select Currencies(Optional)") {
                        Text(displayCurrencies.map(\.rawValue).joined(separator: ", "))
                            .foregroundStyle(.primary)
                    }
                }
            } header: {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Track Wealth Across Global Currencies", systemImage: "globe")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text("Display currencies let you see your total wealth converted into different currencies around the world.")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text("Your base currency will always be included.")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}
