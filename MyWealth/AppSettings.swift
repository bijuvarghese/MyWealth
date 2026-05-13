import Foundation
import Observation

@Observable
final class AppSettings {
    private enum DefaultsKeys {
        static let totalCurrencies = "settings.totalCurrencies"
        static let baseCurrency = "settings.baseCurrency"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
    }

    private let userDefaults: UserDefaults

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

    var hasCompletedOnboarding: Bool {
        didSet {
            persistOnboardingStatus()
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let savedBaseCode = userDefaults.string(forKey: DefaultsKeys.baseCurrency)
        self.baseCurrency = savedBaseCode.flatMap(Asset.CurrencyType.init(rawValue:)) ?? .usd

        let savedCodes = userDefaults.stringArray(forKey: DefaultsKeys.totalCurrencies) ?? []
        let savedCurrencies = savedCodes.compactMap(Asset.CurrencyType.init(rawValue:))
        self.totalCurrencies = savedCurrencies.isEmpty ? [.usd, .inr] : savedCurrencies

        let hasSavedCurrencySettings = savedBaseCode != nil || !savedCodes.isEmpty
        self.hasCompletedOnboarding = userDefaults.bool(forKey: DefaultsKeys.hasCompletedOnboarding) || hasSavedCurrencySettings
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
        self.hasCompletedOnboarding = true
    }

    private func persistTotalCurrencies() {
        userDefaults.set(totalCurrencies.map(\.rawValue), forKey: DefaultsKeys.totalCurrencies)
    }

    private func persistBaseCurrency() {
        userDefaults.set(baseCurrency.rawValue, forKey: DefaultsKeys.baseCurrency)
    }

    private func persistOnboardingStatus() {
        userDefaults.set(hasCompletedOnboarding, forKey: DefaultsKeys.hasCompletedOnboarding)
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
