import Foundation
import SwiftData

@MainActor
enum NetWorthGoalStore {
    enum StoreError: LocalizedError {
        case invalidDraft(Set<NetWorthGoalValidationIssue>)

        var errorDescription: String? {
            switch self {
            case .invalidDraft:
                return AppLocalization.string(
                    "Enter a positive target amount, supported currency, and valid target date."
                )
            }
        }
    }

    static func canonicalGoal(from goals: [NetWorthGoal]) -> NetWorthGoal? {
        goals
            .filter(\.hasValidStoredValues)
            .sorted(by: isPreferred)
            .first
    }

    static func canonicalGoal(in context: ModelContext) throws -> NetWorthGoal? {
        canonicalGoal(from: try context.fetch(FetchDescriptor<NetWorthGoal>()))
    }

    @discardableResult
    static func upsert(
        _ draft: NetWorthGoalDraft,
        in context: ModelContext,
        now: Date = Date(),
        calendar: Calendar = .current
    ) throws -> NetWorthGoal {
        let issues = draft.validationIssues(today: now, calendar: calendar)
        guard issues.isEmpty else { throw StoreError.invalidDraft(issues) }

        let allGoals = try context.fetch(FetchDescriptor<NetWorthGoal>())
        let goal: NetWorthGoal
        if let existing = canonicalGoal(from: allGoals) {
            goal = existing
            goal.targetAmount = draft.targetAmount
            goal.currencyCode = draft.currency.rawValue
            goal.targetDate = draft.targetDate
            goal.updatedAt = now
        } else {
            goal = NetWorthGoal(
                targetAmount: draft.targetAmount,
                currency: draft.currency,
                targetDate: draft.targetDate,
                createdAt: now,
                updatedAt: now
            )
            context.insert(goal)
        }

        for duplicate in allGoals where duplicate !== goal {
            context.delete(duplicate)
        }
        try context.save()
        return goal
    }

    static func deleteAll(in context: ModelContext) throws {
        for goal in try context.fetch(FetchDescriptor<NetWorthGoal>()) {
            context.delete(goal)
        }
        try context.save()
    }

    @discardableResult
    static func reconcile(in context: ModelContext) throws -> NetWorthGoal? {
        let goals = try context.fetch(FetchDescriptor<NetWorthGoal>())
        let canonical = canonicalGoal(from: goals)
        for goal in goals where goal !== canonical {
            context.delete(goal)
        }
        try context.save()
        return canonical
    }

    private static func isPreferred(_ lhs: NetWorthGoal, _ rhs: NetWorthGoal) -> Bool {
        if lhs.displayUpdatedAt != rhs.displayUpdatedAt {
            return lhs.displayUpdatedAt > rhs.displayUpdatedAt
        }
        if lhs.displayCreatedAt != rhs.displayCreatedAt {
            return lhs.displayCreatedAt > rhs.displayCreatedAt
        }
        return lhs.displayStableIdentifier < rhs.displayStableIdentifier
    }
}
