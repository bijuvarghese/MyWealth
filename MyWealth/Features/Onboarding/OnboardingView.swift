import SwiftUI

struct OnboardingView: View {
    @Bindable var settings: AppSettings
    @Environment(ContainerHolder.self) private var containerHolder

    @State private var currentStep: OnboardingStep = .baseCurrency
    @State private var baseCurrency: Asset.CurrencyType = .usd
    @State private var displayCurrencies: [Asset.CurrencyType] = [.usd, .inr]
    @State private var remindersEnabled = false
    @State private var reminderType: ReminderType = .reviewPortfolio
    @State private var reminderFrequency: ReminderFrequency = .weekly
    @State private var iCloudSyncEnabled = false
    @State private var didLoadInitialValues = false
    @State private var didLogOnboardingStart = false

    var body: some View {
        NavigationStack {
            ZStack {
                RadialDotBackground(dotRadius: 1, spacing: 20)
                    .ignoresSafeArea(.all)

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
                    case .iCloudSync:
                        OnboardingICloudStepView(iCloudSyncEnabled: $iCloudSyncEnabled)
                    }
                }
            }
            .navigationTitle("Setup Wealth Map")
            .safeAreaInset(edge: .bottom) {
                bottomButton
            }
        }
        .onAppear {
            guard !didLoadInitialValues else { return }

            logOnboardingStartedIfNeeded()
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
            Text(currentStep == .iCloudSync ? "Finish Setup" : "Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .frame(height: 44)
        .buttonStyle(.borderedProminent)
        .disabled(currentStep == .displayCurrencies && displayCurrencies.isEmpty)
        .padding()
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
            currentStep = .iCloudSync

        case .iCloudSync:
            // Apply iCloud sync preference before completing onboarding.
            settings.iCloudSyncEnabled = iCloudSyncEnabled
            if iCloudSyncEnabled {
                containerHolder.switchSync(enabled: true)
            }
            AnalyticsService.shared.log(
                .onboardingCompleted,
                parameters: [.sourceScreen: AnalyticsService.SourceScreen.onboarding.rawValue]
            )
            settings.completeOnboarding(
                baseCurrency: baseCurrency,
                displayCurrencies: displayCurrencies
            )
        }
    }

    private func logOnboardingStartedIfNeeded() {
        guard !didLogOnboardingStart else { return }
        didLogOnboardingStart = true
        AnalyticsService.shared.log(
            .onboardingStarted,
            parameters: [.sourceScreen: AnalyticsService.SourceScreen.onboarding.rawValue]
        )
    }
}

private struct OnboardingBaseCurrencyStepView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var baseCurrency: Asset.CurrencyType

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryTextColor: Color {
        primaryTextColor
    }

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
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            } header: {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Select your base currency", systemImage: "globe")
                            .font(.title3.bold())
                            .foregroundStyle(primaryTextColor)

                        Text("Your base currency is the foundation of your Wealth Map.")
                            .font(.headline)
                            .foregroundStyle(primaryTextColor)

                        Text("It’s used to calculate your total wealth and convert assets using current exchange rates.")
                            .font(.body)
                            .foregroundStyle(primaryTextColor)

                        Text("You can update this later in Settings.")
                            .font(.footnote)
                            .foregroundStyle(secondaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

private struct OnboardingDisplayCurrencyStepView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var displayCurrencies: [Asset.CurrencyType]
    let baseCurrency: Asset.CurrencyType

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryTextColor: Color {
        primaryTextColor
    }

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
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))

                NavigationLink {
                    DisplayCurrencyArrangementView(
                        currencies: $displayCurrencies,
                        requiredCurrency: baseCurrency
                    )
                } label: {
                    LabeledContent("Arrange Selected") {
                        Text(displayCurrencies.map(\.rawValue).joined(separator: ", "))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            } header: {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Track Wealth Across Global Currencies", systemImage: "globe")
                        .font(.title3.bold())
                        .foregroundStyle(primaryTextColor)
                    Text("View your net worth in multiple global currencies for a clearer perspective on your wealth around the world.")
                        .font(.body)
                        .foregroundStyle(primaryTextColor)
                    Text("Your base currency will always be included.")
                        .font(.footnote)
                        .foregroundStyle(secondaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}
