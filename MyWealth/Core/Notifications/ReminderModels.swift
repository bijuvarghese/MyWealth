import Foundation

// MARK: - Reminder Enums

enum ReminderFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    
    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
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

enum ReminderType: String, Codable, CaseIterable {
    case addAsset
    case updateAssets
    case reviewPortfolio
    
    var displayName: String {
        switch self {
        case .addAsset:
            return "Add Asset"
        case .updateAssets:
            return "Update Assets"
        case .reviewPortfolio:
            return "Review Portfolio"
        }
    }
    
    var notificationMessages: [String] {
        switch self {
        case .addAsset:
            return [
                "Add your latest investments to Wealth Map.",
                "Keep your wealth journey updated."
            ]
        case .updateAssets:
            return [
                "Update your asset values today.",
                "Your portfolio snapshot is waiting."
            ]
        case .reviewPortfolio:
            return [
                "Review your Wealth Map portfolio.",
                "Time for a quick financial check-in."
            ]
        }
    }
    
    var randomMessage: String {
        notificationMessages.randomElement() ?? ""
    }
}

// MARK: - Reminder Preference Model

struct ReminderPreference: Codable {
    var isEnabled: Bool
    var hasMadeChoice: Bool
    var frequency: ReminderFrequency
    var reminderTime: Date
    var reminderType: ReminderType
    var lastReminderDate: Date?
    
    init(
        isEnabled: Bool = false,
        hasMadeChoice: Bool = false,
        frequency: ReminderFrequency = .weekly,
        reminderTime: Date = Self.defaultReminderTime(),
        reminderType: ReminderType = .reviewPortfolio,
        lastReminderDate: Date? = nil
    ) {
        self.isEnabled = isEnabled
        self.hasMadeChoice = hasMadeChoice
        self.frequency = frequency
        self.reminderTime = reminderTime
        self.reminderType = reminderType
        self.lastReminderDate = lastReminderDate
    }

    enum CodingKeys: String, CodingKey {
        case isEnabled
        case hasMadeChoice
        case frequency
        case reminderTime
        case reminderType
        case lastReminderDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        self.hasMadeChoice = try container.decodeIfPresent(Bool.self, forKey: .hasMadeChoice) ?? true
        self.frequency = try container.decode(ReminderFrequency.self, forKey: .frequency)
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
}
