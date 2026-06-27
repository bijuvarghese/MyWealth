import Foundation

// MARK: - Reminder Enums

enum ReminderFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    
    var displayName: String {
        localizedDisplayName()
    }

    func localizedDisplayName(locale: Locale = .current) -> String {
        switch self {
        case .daily:
            return AppLocalization.string("Daily", locale: locale)
        case .weekly:
            return AppLocalization.string("Weekly", locale: locale)
        case .monthly:
            return AppLocalization.string("Monthly", locale: locale)
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .daily:
            return 24 * 60 * 60 // 1 day
        case .weekly:
            return 7 * 24 * 60 * 60 // 7 days
        case .monthly:
            return 30 * 24 * 60 * 60 // 30 days
        }
    }
}

enum ReminderWeekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var displayName: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        return formatter.weekdaySymbols[rawValue - 1]
    }
}

enum ReminderType: String, Codable, CaseIterable {
    case addAsset
    case updateAssets
    case reviewPortfolio
    
    var displayName: String {
        localizedDisplayName()
    }

    func localizedDisplayName(locale: Locale = .current) -> String {
        switch self {
        case .addAsset:
            return AppLocalization.string("Add Asset", locale: locale)
        case .updateAssets:
            return AppLocalization.string("Update Assets", locale: locale)
        case .reviewPortfolio:
            return AppLocalization.string("Review Portfolio", locale: locale)
        }
    }
    
    var notificationMessages: [String] {
        localizedNotificationMessages()
    }

    func localizedNotificationMessages(locale: Locale = .current) -> [String] {
        switch self {
        case .addAsset:
            return [
                AppLocalization.string("Add your latest investments to Wealth Map.", locale: locale),
                AppLocalization.string("Keep your wealth journey updated.", locale: locale)
            ]
        case .updateAssets:
            return [
                AppLocalization.string("Update your asset values today.", locale: locale),
                AppLocalization.string("Your portfolio snapshot is waiting.", locale: locale)
            ]
        case .reviewPortfolio:
            return [
                AppLocalization.string("Review your Wealth Map portfolio.", locale: locale),
                AppLocalization.string("Time for a quick financial check-in.", locale: locale)
            ]
        }
    }
    
    var randomMessage: String {
        notificationMessages.randomElement() ?? ""
    }
}

// MARK: - Reminder Preference Model

struct ReminderPreference: Codable {
    static let maximumMonthlyReminderDay = 28

    var isEnabled: Bool
    var hasMadeChoice: Bool
    var frequency: ReminderFrequency
    var weekday: ReminderWeekday
    var monthDay: Int
    var reminderTime: Date
    var reminderType: ReminderType
    var lastReminderDate: Date?
    
    init(
        isEnabled: Bool = false,
        hasMadeChoice: Bool = false,
        frequency: ReminderFrequency = .weekly,
        weekday: ReminderWeekday = Self.defaultWeeklyWeekday(),
        monthDay: Int = Self.defaultMonthlyDay(),
        reminderTime: Date = Self.defaultReminderTime(),
        reminderType: ReminderType = .reviewPortfolio,
        lastReminderDate: Date? = nil
    ) {
        self.isEnabled = isEnabled
        self.hasMadeChoice = hasMadeChoice
        self.frequency = frequency
        self.weekday = weekday
        self.monthDay = Self.normalizedMonthDay(monthDay)
        self.reminderTime = reminderTime
        self.reminderType = reminderType
        self.lastReminderDate = lastReminderDate
    }

    enum CodingKeys: String, CodingKey {
        case isEnabled
        case hasMadeChoice
        case frequency
        case weekday
        case monthDay
        case reminderTime
        case reminderType
        case lastReminderDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.hasMadeChoice = try container.decodeIfPresent(Bool.self, forKey: .hasMadeChoice) ?? true
        self.frequency = try container.decode(ReminderFrequency.self, forKey: .frequency)
        self.weekday = try container.decodeIfPresent(ReminderWeekday.self, forKey: .weekday) ?? Self.defaultWeeklyWeekday()
        self.monthDay = Self.normalizedMonthDay(
            try container.decodeIfPresent(Int.self, forKey: .monthDay) ?? Self.defaultMonthlyDay()
        )
        self.reminderTime = try container.decode(Date.self, forKey: .reminderTime)
        self.reminderType = try container.decode(ReminderType.self, forKey: .reminderType)
        self.lastReminderDate = try container.decodeIfPresent(Date.self, forKey: .lastReminderDate)
    }
    
    static func defaultReminderTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    static func defaultWeeklyWeekday() -> ReminderWeekday {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return ReminderWeekday(rawValue: weekday) ?? .monday
    }

    static func defaultMonthlyDay() -> Int {
        normalizedMonthDay(Calendar.current.component(.day, from: Date()))
    }

    static func normalizedMonthDay(_ day: Int) -> Int {
        min(max(day, 1), maximumMonthlyReminderDay)
    }
}
