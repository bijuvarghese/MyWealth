import Foundation
import Combine
import UserNotifications

class ReminderManager: ObservableObject {
    @Published var isNotificationPermissionGranted = false
    @Published var preference: ReminderPreference {
        didSet {
            scheduleReminder()
        }
    }
    
    static let shared = ReminderManager()
    
    private let preferenceStore = ReminderPreferenceStore()
    private let scheduler = NotificationScheduler.shared
    private let inactivityThreshold: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    private let cooldownPeriod: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {
        self.preference = preferenceStore.preference
        checkNotificationPermissionStatus()
    }
    
    // MARK: - Public Methods
    
    func requestNotificationPermission() {
        scheduler.requestNotificationPermission { [weak self] granted in
            self?.isNotificationPermissionGranted = granted
        }
    }
    
    func enableReminders(
        frequency: ReminderFrequency = .weekly,
        weekday: ReminderWeekday = ReminderPreference.defaultWeeklyWeekday(),
        monthDay: Int = ReminderPreference.defaultMonthlyDay(),
        time: Date = ReminderPreference.defaultReminderTime(),
        type: ReminderType = .reviewPortfolio
    ) {
        preference.isEnabled = true
        preference.hasMadeChoice = true
        preference.frequency = frequency
        preference.weekday = weekday
        preference.monthDay = ReminderPreference.normalizedMonthDay(monthDay)
        preference.reminderTime = time
        preference.reminderType = type
        preferenceStore.preference = preference
    }
    
    func disableReminders() {
        preference.isEnabled = false
        preference.hasMadeChoice = true
        preferenceStore.preference = preference
        scheduler.cancelReminder()
    }
    
    func updateReminderPreference(
        frequency: ReminderFrequency? = nil,
        weekday: ReminderWeekday? = nil,
        monthDay: Int? = nil,
        time: Date? = nil
    ) {
        if let frequency = frequency {
            preference.frequency = frequency
        }
        if let weekday = weekday {
            preference.weekday = weekday
        }
        if let monthDay = monthDay {
            preference.monthDay = ReminderPreference.normalizedMonthDay(monthDay)
        }
        if let time = time {
            preference.reminderTime = time
        }
        preferenceStore.preference = preference
    }
    
    func handleNotificationTap(with userInfo: [AnyHashable: Any]) {
        scheduler.clearDeliveredReminderBadge()

        guard let reminderTypeRaw = userInfo["reminderType"] as? String,
              let reminderType = ReminderType(rawValue: reminderTypeRaw) else {
            return
        }
        
        print("User tapped reminder for: \(reminderType.displayName)")
        // Could trigger navigation or perform actions based on reminder type
    }
    
    // MARK: - Smart Reminder Logic
    
    func shouldSendActiveReminder(lastAssetUpdateDate: Date?) -> Bool {
        // Check if user recently updated assets
        guard let lastUpdate = lastAssetUpdateDate else {
            return true // Empty portfolio, send reminder
        }
        
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        
        // Check if within cooldown period
        if let lastReminder = preference.lastReminderDate {
            let timeSinceLastReminder = Date().timeIntervalSince(lastReminder)
            if timeSinceLastReminder < cooldownPeriod {
                return false // Skip duplicate reminder within cooldown
            }
        }
        
        // Send reminder if user inactive beyond threshold
        return timeSinceUpdate > inactivityThreshold
    }
    
    func recordReminderSent() {
        preference.lastReminderDate = Date()
        preferenceStore.preference = preference
    }
    
    // MARK: - Private Methods
    
    private func checkNotificationPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] (settings: UNNotificationSettings) in
            let isGranted = settings.authorizationStatus == UNAuthorizationStatus.authorized
            DispatchQueue.main.async {
                self?.isNotificationPermissionGranted = isGranted
            }
        }
    }
    
    private func scheduleReminder() {
        guard preference.isEnabled && isNotificationPermissionGranted else {
            return
        }
        scheduler.scheduleReminder(preference: preference)
    }
}
