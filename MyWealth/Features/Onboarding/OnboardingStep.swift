import Foundation

enum OnboardingStep: Int, CaseIterable {
    case baseCurrency
    case displayCurrencies
    case reminders
    case iCloudSync

    var title: String {
        switch self {
        case .baseCurrency:
            "Choose Base Currency"
        case .displayCurrencies:
            "Choose Display Currencies"
        case .reminders:
            "Set Up Reminders"
        case .iCloudSync:
            "Back Up to iCloud"
        }
    }
}
