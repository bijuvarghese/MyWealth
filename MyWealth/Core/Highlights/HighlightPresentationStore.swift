import Foundation

enum WealthHighlightKind: String, CaseIterable, Identifiable, Codable {
    case weekly
    case monthly

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .weekly:
            AppLocalization.string("Weekly Highlights")
        case .monthly:
            AppLocalization.string("Monthly Highlights")
        }
    }

    var localizedPeriodName: String {
        switch self {
        case .weekly:
            AppLocalization.string("week")
        case .monthly:
            AppLocalization.string("month")
        }
    }
}

struct WealthHighlightPeriod: Identifiable, Equatable, Codable {
    let kind: WealthHighlightKind
    let interval: DateInterval
    let referenceDate: Date
    let identifier: String

    var id: String { identifier }

    init?(
        kind: WealthHighlightKind,
        referenceDate: Date,
        calendar: Calendar = .current
    ) {
        let component: Calendar.Component = kind == .weekly ? .weekOfYear : .month
        guard let interval = calendar.dateInterval(of: component, for: referenceDate) else {
            return nil
        }

        let identifier: String
        switch kind {
        case .weekly:
            let components = calendar.dateComponents(
                [.era, .yearForWeekOfYear, .weekOfYear],
                from: interval.start
            )
            guard
                let era = components.era,
                let year = components.yearForWeekOfYear,
                let week = components.weekOfYear
            else {
                return nil
            }
            identifier = "weekly-\(era)-\(year)-\(week)"
        case .monthly:
            let components = calendar.dateComponents([.era, .year, .month], from: interval.start)
            guard
                let era = components.era,
                let year = components.year,
                let month = components.month
            else {
                return nil
            }
            identifier = "monthly-\(era)-\(year)-\(month)"
        }

        self.kind = kind
        self.interval = interval
        self.referenceDate = referenceDate
        self.identifier = identifier
    }
}

@MainActor
final class HighlightPresentationStore {
    private enum DefaultsKeys {
        static let dismissedWeekly = "highlights.lastDismissedWeeklyPeriod"
        static let dismissedMonthly = "highlights.lastDismissedMonthlyPeriod"
        static let pendingWeekly = "highlights.pendingWeeklyPeriod"
        static let pendingMonthly = "highlights.pendingMonthlyPeriod"
    }

    private let userDefaults: UserDefaults
    private let calendar: Calendar

    init(
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.userDefaults = userDefaults
        self.calendar = calendar
    }

    func automaticPeriod(
        on date: Date = Date(),
        onboardingComplete: Bool
    ) -> WealthHighlightPeriod? {
        guard onboardingComplete else {
            return nil
        }

        if let pendingMonthly = pendingPeriod(for: .monthly) {
            return pendingMonthly
        }
        if let pendingWeekly = pendingPeriod(for: .weekly) {
            return pendingWeekly
        }

        if let monthlyPeriod = monthlyDuePeriod(on: date),
           lastDismissedIdentifier(for: .monthly) != monthlyPeriod.identifier {
            markOverlappingWeeklyIfNeeded(on: date)
            markPending(monthlyPeriod)
            return monthlyPeriod
        }

        guard
            let weeklyPeriod = weeklyDuePeriod(on: date),
            lastDismissedIdentifier(for: .weekly) != weeklyPeriod.identifier
        else {
            return nil
        }

        markPending(weeklyPeriod)
        return weeklyPeriod
    }

    func markDismissed(_ period: WealthHighlightPeriod) {
        userDefaults.set(period.identifier, forKey: dismissedKey(for: period.kind))
        userDefaults.removeObject(forKey: pendingKey(for: period.kind))
    }

    func lastDismissedIdentifier(for kind: WealthHighlightKind) -> String? {
        userDefaults.string(forKey: dismissedKey(for: kind))
    }

    private func markPending(_ period: WealthHighlightPeriod) {
        guard let data = try? JSONEncoder().encode(period) else {
            return
        }
        userDefaults.set(data, forKey: pendingKey(for: period.kind))
    }

    private func monthlyDuePeriod(on date: Date) -> WealthHighlightPeriod? {
        guard
            let currentMonth = calendar.dateInterval(of: .month, for: date),
            let previousMonthDate = calendar.date(
                byAdding: .month,
                value: -1,
                to: currentMonth.start
            )
        else {
            return nil
        }

        return WealthHighlightPeriod(
            kind: .monthly,
            referenceDate: previousMonthDate,
            calendar: calendar
        )
    }

    private func weeklyDuePeriod(on date: Date) -> WealthHighlightPeriod? {
        let weekday = calendar.component(.weekday, from: date)
        let daysSinceSaturday = (weekday - 7 + 7) % 7
        guard
            let mostRecentSaturday = calendar.date(
                byAdding: .day,
                value: -daysSinceSaturday,
                to: date
            )
        else {
            return nil
        }

        return WealthHighlightPeriod(
            kind: .weekly,
            referenceDate: mostRecentSaturday,
            calendar: calendar
        )
    }

    private func markOverlappingWeeklyIfNeeded(on date: Date) {
        guard
            pendingPeriod(for: .weekly) == nil,
            let currentMonth = calendar.dateInterval(of: .month, for: date),
            calendar.component(.weekday, from: currentMonth.start) == 7,
            let weeklyPeriod = WealthHighlightPeriod(
                kind: .weekly,
                referenceDate: currentMonth.start,
                calendar: calendar
            ),
            lastDismissedIdentifier(for: .weekly) != weeklyPeriod.identifier
        else {
            return
        }

        markPending(weeklyPeriod)
    }

    private func pendingPeriod(for kind: WealthHighlightKind) -> WealthHighlightPeriod? {
        guard
            let data = userDefaults.data(forKey: pendingKey(for: kind)),
            let period = try? JSONDecoder().decode(WealthHighlightPeriod.self, from: data),
            period.kind == kind
        else {
            return nil
        }
        return period
    }

    private func dismissedKey(for kind: WealthHighlightKind) -> String {
        switch kind {
        case .weekly:
            DefaultsKeys.dismissedWeekly
        case .monthly:
            DefaultsKeys.dismissedMonthly
        }
    }

    private func pendingKey(for kind: WealthHighlightKind) -> String {
        switch kind {
        case .weekly:
            DefaultsKeys.pendingWeekly
        case .monthly:
            DefaultsKeys.pendingMonthly
        }
    }
}
