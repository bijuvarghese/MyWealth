import Foundation
import Observation

@Observable
final class AppSettings {
    typealias OnboardingStatus = (isComplete: Bool, missingSteps: Set<OnboardingStep>)

    private enum DefaultsKeys {
        static let totalCurrencies = "settings.totalCurrencies"
        static let baseCurrency = "settings.baseCurrency"
        static let usesCompactCurrencyTotals = "settings.usesCompactCurrencyTotals"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
    }

    private let userDefaults: UserDefaults
    @ObservationIgnored private let hasMadeReminderChoice: () -> Bool
    private var hasCompletedCurrencyOnboarding: Bool

    var baseCurrency: Asset.CurrencyType {
        didSet {
            persistBaseCurrency()
        }
    }

    var totalCurrencies: [Asset.CurrencyType] {
        didSet {
            persistTotalCurrencies()
        }
    }

    var usesCompactCurrencyTotals: Bool {
        didSet {
            persistUsesCompactCurrencyTotals()
        }
    }

    var hasCompletedOnboarding: OnboardingStatus {
        onboardingStatus()
    }

    func onboardingStatus() -> OnboardingStatus {
        let hasMadeReminderChoice = hasMadeReminderChoice()
        let missingSteps = missingOnboardingSteps(hasMadeReminderChoice: hasMadeReminderChoice)
        return (missingSteps.isEmpty, missingSteps)
    }

    init(
        userDefaults: UserDefaults = .standard,
        hasMadeReminderChoice: @escaping () -> Bool = { ReminderManager.shared.preference.hasMadeChoice }
    ) {
        self.userDefaults = userDefaults
        self.hasMadeReminderChoice = hasMadeReminderChoice

        let savedBaseCode = userDefaults.string(forKey: DefaultsKeys.baseCurrency)
        self.baseCurrency = savedBaseCode.flatMap(Asset.CurrencyType.init(rawValue:)) ?? .usd

        let savedCodes = userDefaults.stringArray(forKey: DefaultsKeys.totalCurrencies) ?? []
        let savedCurrencies = savedCodes.compactMap(Asset.CurrencyType.init(rawValue:))
        self.totalCurrencies = savedCurrencies.isEmpty ? [.usd, .inr] : savedCurrencies
        self.usesCompactCurrencyTotals = userDefaults.bool(forKey: DefaultsKeys.usesCompactCurrencyTotals)

        let hasSavedCurrencySettings = savedBaseCode != nil || !savedCodes.isEmpty
        self.hasCompletedCurrencyOnboarding = userDefaults.bool(forKey: DefaultsKeys.hasCompletedOnboarding) || hasSavedCurrencySettings
    }

    func setBaseCurrency(_ currency: Asset.CurrencyType) {
        baseCurrency = currency
        if !totalCurrencies.contains(currency) {
            totalCurrencies.insert(currency, at: 0)
        }
    }

    func toggleTotalCurrency(_ currency: Asset.CurrencyType) {
        if totalCurrencies.contains(currency) {
            if totalCurrencies.count > 1 {
                totalCurrencies.removeAll { $0 == currency }
            }
        } else {
            totalCurrencies.append(currency)
            totalCurrencies.sort { $0.rawValue < $1.rawValue }
        }
    }

    func completeOnboarding(baseCurrency: Asset.CurrencyType, displayCurrencies: [Asset.CurrencyType]) {
        self.baseCurrency = baseCurrency
        self.totalCurrencies = normalizedDisplayCurrencies(displayCurrencies, including: baseCurrency)
        self.hasCompletedCurrencyOnboarding = true
        persistOnboardingStatus()
    }

    func firstMissingOnboardingStep() -> OnboardingStep {
        let missingSteps = hasCompletedOnboarding.missingSteps
        return OnboardingStep.allCases.first { missingSteps.contains($0) } ?? .baseCurrency
    }

    private func persistTotalCurrencies() {
        userDefaults.set(totalCurrencies.map(\.rawValue), forKey: DefaultsKeys.totalCurrencies)
    }

    private func persistBaseCurrency() {
        userDefaults.set(baseCurrency.rawValue, forKey: DefaultsKeys.baseCurrency)
    }

    private func persistUsesCompactCurrencyTotals() {
        userDefaults.set(usesCompactCurrencyTotals, forKey: DefaultsKeys.usesCompactCurrencyTotals)
    }

    private func persistOnboardingStatus() {
        userDefaults.set(hasCompletedCurrencyOnboarding, forKey: DefaultsKeys.hasCompletedOnboarding)
    }

    private func missingOnboardingSteps(hasMadeReminderChoice: Bool) -> Set<OnboardingStep> {
        var missingSteps = Set<OnboardingStep>()

        if !hasCompletedCurrencyOnboarding {
            missingSteps.insert(.baseCurrency)
            missingSteps.insert(.displayCurrencies)
        }

        if !hasMadeReminderChoice {
            missingSteps.insert(.reminders)
        }

        return missingSteps
    }

    private func normalizedDisplayCurrencies(
        _ currencies: [Asset.CurrencyType],
        including baseCurrency: Asset.CurrencyType
    ) -> [Asset.CurrencyType] {
        ([baseCurrency] + currencies).reduce(into: [Asset.CurrencyType]()) { result, currency in
            guard currency != .none, !result.contains(currency) else {
                return
            }
            result.append(currency)
        }
    }
}
