import Foundation
import SwiftData

@Model
final class NetWorthGoal {
    var stableIdentifier: String? = nil
    var targetAmount: Double? = nil
    var currencyCode: String? = nil
    var targetDate: Date? = nil
    var createdAt: Date? = nil
    var updatedAt: Date? = nil

    init(
        targetAmount: Double,
        currency: Asset.CurrencyType,
        targetDate: Date,
        stableIdentifier: String = UUID().uuidString,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.stableIdentifier = stableIdentifier
        self.targetAmount = targetAmount
        self.currencyCode = currency.rawValue
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var displayTargetAmount: Double { targetAmount ?? 0 }
    var displayCurrency: Asset.CurrencyType {
        Asset.CurrencyType(rawValue: currencyCode ?? "") ?? .none
    }
    var displayTargetDate: Date { targetDate ?? .distantPast }
    var displayCreatedAt: Date { createdAt ?? .distantPast }
    var displayUpdatedAt: Date { updatedAt ?? .distantPast }
    var displayStableIdentifier: String { stableIdentifier ?? "" }

    var hasValidStoredValues: Bool {
        displayTargetAmount.isFinite
            && displayTargetAmount > 0
            && displayCurrency != .none
            && targetDate != nil
            && createdAt != nil
            && updatedAt != nil
            && !displayStableIdentifier.isEmpty
    }
}

struct NetWorthGoalDraft: Equatable {
    var targetAmount: Double
    var currency: Asset.CurrencyType
    var targetDate: Date

    func validationIssues(
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Set<NetWorthGoalValidationIssue> {
        var issues: Set<NetWorthGoalValidationIssue> = []
        if !targetAmount.isFinite || targetAmount <= 0 {
            issues.insert(.targetAmount)
        }
        if currency == .none {
            issues.insert(.currency)
        }
        if calendar.startOfDay(for: targetDate) < calendar.startOfDay(for: today) {
            issues.insert(.targetDate)
        }
        return issues
    }
}

enum NetWorthGoalValidationIssue: Hashable {
    case targetAmount
    case currency
    case targetDate
}
