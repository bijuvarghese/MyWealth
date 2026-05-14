import Foundation

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
