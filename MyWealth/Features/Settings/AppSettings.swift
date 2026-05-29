import Foundation
import Observation

@Observable
final class AppSettings {
    typealias OnboardingStatus = (isComplete: Bool, missingSteps: Set<OnboardingStep>)

    private enum DefaultsKeys {
        static let totalCurrencies = "settings.totalCurrencies"
        static let baseCurrency = "settings.baseCurrency"
        static let usesCompactCurrencyTotals = "settings.usesCompactCurrencyTotals"
        static let includeIgnoredAssetsInPortfolio = "settings.includeIgnoredAssetsInPortfolio"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
        static let iCloudSyncEnabled = "settings.iCloudSyncEnabled"
        static let hasSeenICloudOnboarding = "settings.hasSeenICloudOnboarding"
    }

    private let userDefaults: UserDefaults
    @ObservationIgnored private let hasMadeReminderChoice: () -> Bool
    private var hasCompletedCurrencyOnboarding: Bool
    private var hasSeenICloudOnboarding: Bool

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

    var includeIgnoredAssetsInPortfolio: Bool {
        didSet {
            userDefaults.set(includeIgnoredAssetsInPortfolio, forKey: DefaultsKeys.includeIgnoredAssetsInPortfolio)
        }
    }

    var iCloudSyncEnabled: Bool {
        didSet {
            userDefaults.set(iCloudSyncEnabled, forKey: DefaultsKeys.iCloudSyncEnabled)
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
        let restoredBaseCurrency = savedBaseCode.flatMap(Asset.CurrencyType.init(rawValue:)) ?? .usd
        self.baseCurrency = restoredBaseCurrency

        let savedCodes = userDefaults.stringArray(forKey: DefaultsKeys.totalCurrencies) ?? []
        let savedCurrencies = savedCodes.compactMap(Asset.CurrencyType.init(rawValue:))
        self.totalCurrencies = savedCurrencies.isEmpty
            ? [.usd, .inr]
            : AppSettings.normalizedDisplayCurrencies(savedCurrencies, including: restoredBaseCurrency)
        self.usesCompactCurrencyTotals = userDefaults.bool(forKey: DefaultsKeys.usesCompactCurrencyTotals)
        self.includeIgnoredAssetsInPortfolio = userDefaults.bool(forKey: DefaultsKeys.includeIgnoredAssetsInPortfolio)
        self.iCloudSyncEnabled = userDefaults.bool(forKey: DefaultsKeys.iCloudSyncEnabled)

        let hasSavedCurrencySettings = savedBaseCode != nil || !savedCodes.isEmpty
        self.hasCompletedCurrencyOnboarding = userDefaults.bool(forKey: DefaultsKeys.hasCompletedOnboarding) || hasSavedCurrencySettings
        // Only true once the user has explicitly gone through the iCloud onboarding step.
        // Existing users who upgrade will have this absent from UserDefaults (defaults to false),
        // so they'll be shown the step — jumping directly to it since their other steps are done.
        self.hasSeenICloudOnboarding = userDefaults.bool(forKey: DefaultsKeys.hasSeenICloudOnboarding)
    }

    func setBaseCurrency(_ currency: Asset.CurrencyType) {
        baseCurrency = currency
        if !totalCurrencies.contains(currency) {
            totalCurrencies.insert(currency, at: 0)
        }
    }

    func toggleTotalCurrency(_ currency: Asset.CurrencyType) {
        guard currency != .none else {
            return
        }

        if totalCurrencies.contains(currency) {
            if totalCurrencies.count > 1 && currency != baseCurrency {
                totalCurrencies.removeAll { $0 == currency }
            }
        } else {
            totalCurrencies.append(currency)
        }
    }

    func moveTotalCurrencies(fromOffsets source: IndexSet, toOffset destination: Int) {
        var reorderedCurrencies = totalCurrencies
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
        totalCurrencies = Self.normalizedDisplayCurrencies(reorderedCurrencies, including: baseCurrency)
    }

    func completeOnboarding(baseCurrency: Asset.CurrencyType, displayCurrencies: [Asset.CurrencyType]) {
        self.baseCurrency = baseCurrency
        self.totalCurrencies = Self.normalizedDisplayCurrencies(displayCurrencies, including: baseCurrency)
        self.hasCompletedCurrencyOnboarding = true
        self.hasSeenICloudOnboarding = true
        persistOnboardingStatus()
        userDefaults.set(true, forKey: DefaultsKeys.hasSeenICloudOnboarding)
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

    func portfolioCalculationAssets(from assets: [Asset]) -> [Asset] {
        includeIgnoredAssetsInPortfolio
            ? assets
            : assets.filter(\.participatesInPortfolioCalculations)
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

        if !hasSeenICloudOnboarding {
            missingSteps.insert(.iCloudSync)
        }

        return missingSteps
    }

    private static func normalizedDisplayCurrencies(
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
