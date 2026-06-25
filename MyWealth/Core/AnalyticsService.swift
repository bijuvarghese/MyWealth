import Foundation

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

struct AnalyticsService {
    static let shared = AnalyticsService()

    enum Event: String, CaseIterable {
        case onboardingStarted = "onboarding_started"
        case onboardingCompleted = "onboarding_completed"
        case dashboardViewed = "dashboard_viewed"
        case netWorthSummaryViewed = "networth_summary_viewed"
        case assetAddStarted = "asset_add_started"
        case assetAdded = "asset_added"
        case liabilityAddStarted = "liability_add_started"
        case liabilityAdded = "liability_added"
        case goalCreated = "goal_created"
        case goalUpdated = "goal_updated"
        case budgetCreated = "budget_created"
        case budgetUpdated = "budget_updated"
        case fireCalculatorViewed = "fire_calculator_viewed"
        case fireCalculatorCompleted = "fire_calculator_completed"
        case settingsViewed = "settings_viewed"
    }

    enum Parameter: String, CaseIterable {
        case sourceScreen = "source_screen"
        case assetType = "asset_type"
        case liabilityType = "liability_type"
        case goalType = "goal_type"
        case budgetType = "budget_type"
        case calculatorMode = "calculator_mode"
        case appVersion = "app_version"
    }

    enum SourceScreen: String {
        case onboarding
        case dashboard
        case assets
        case netWorth = "networth"
        case settings
        case fireCalculator = "fire_calculator"
    }

    enum NonFatalFlow: String {
        case localCalculation = "local_calculation"
        case importFailure = "import_failure"
        case syncFailure = "sync_failure"
    }

    static let disallowedParameterNames: Set<String> = [
        "balance",
        "amount",
        "net_worth",
        "income",
        "expense_value",
        "account_name",
        "institution_name",
        "transaction_name",
        "free_text_notes",
        "email",
        "name",
        "phone"
    ]

    private static let allowedParameterNames = Set(Parameter.allCases.map(\.rawValue))

    func log(_ event: Event, parameters: [Parameter: String] = [:]) {
        var rawParameters = Dictionary(uniqueKeysWithValues: parameters.map { ($0.key.rawValue, $0.value) })
        rawParameters[Parameter.appVersion.rawValue] = AppInfo.fullVersion
        let sanitizedParameters = Self.sanitizedRawParameters(rawParameters)

        #if DEBUG
        debugPrint("Analytics event:", event.rawValue, sanitizedParameters)
        #endif

        #if canImport(FirebaseAnalytics)
        guard Self.firebaseIsConfigured else { return }
        Analytics.logEvent(event.rawValue, parameters: sanitizedParameters)
        #endif

        #if canImport(FirebaseCrashlytics)
        guard Self.firebaseIsConfigured else { return }
        Crashlytics.crashlytics().log(Self.breadcrumb(event: event, parameters: sanitizedParameters))
        #endif
    }

    func recordNonFatal(_ error: Error, flow: NonFatalFlow, parameters: [Parameter: String] = [:]) {
        var rawParameters = Dictionary(uniqueKeysWithValues: parameters.map { ($0.key.rawValue, $0.value) })
        if rawParameters[Parameter.sourceScreen.rawValue] == nil {
            rawParameters[Parameter.sourceScreen.rawValue] = flow.rawValue
        }
        rawParameters[Parameter.appVersion.rawValue] = AppInfo.fullVersion
        let sanitizedParameters = Self.sanitizedRawParameters(rawParameters)

        #if DEBUG
        debugPrint("Analytics non-fatal:", flow.rawValue, sanitizedParameters, error.localizedDescription)
        #endif

        #if canImport(FirebaseCrashlytics)
        guard Self.firebaseIsConfigured else { return }
        Crashlytics.crashlytics().record(error: error, userInfo: sanitizedParameters)
        #endif
    }

    static func sanitizedRawParameters(_ parameters: [String: String]) -> [String: String] {
        parameters.reduce(into: [String: String]()) { result, entry in
            let key = entry.key
            let value = entry.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            guard allowedParameterNames.contains(key) else { return }
            guard !disallowedParameterNames.contains(key) else { return }
            result[key] = value
        }
    }

    static func valueName(_ value: String) -> String {
        let scalars = value
            .lowercased()
            .unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) ? Character($0) : "_" }
        let collapsed = String(scalars).split(separator: "_").joined(separator: "_")
        return collapsed.isEmpty ? "unknown" : collapsed
    }

    private static func breadcrumb(event: Event, parameters: [String: String]) -> String {
        let parameterSummary = parameters
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ",")
        return parameterSummary.isEmpty ? event.rawValue : "\(event.rawValue) \(parameterSummary)"
    }

    private static var firebaseIsConfigured: Bool {
        #if canImport(FirebaseCore)
        FirebaseApp.app() != nil
        #else
        false
        #endif
    }
}
