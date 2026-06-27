import Foundation
import UserNotifications

class NotificationScheduler {
    static let shared = NotificationScheduler()
    static let reminderNotificationIdentifier = "com.mywealth.reminder.portfolio-review"
    
    private init() {}
    
    // MARK: - Permission Handling
    
    func requestNotificationPermission(completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
            Task { @MainActor in
                completion(granted)
            }
        }
    }
    
    // MARK: - Scheduling
    
    func scheduleReminder(preference: ReminderPreference) {
        // Cancel existing reminders first
        cancelReminder()
        
        guard preference.isEnabled else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = AppLocalization.string("Wealth Map")
        content.body = preference.reminderType.randomMessage
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Add custom data to identify reminder type
        content.userInfo = [
            "reminderType": preference.reminderType.rawValue,
            "scheduledAt": Date().timeIntervalSince1970
        ]
        
        // Calculate trigger time
        let trigger = createTrigger(from: preference)
        let request = UNNotificationRequest(
            identifier: Self.reminderNotificationIdentifier,
            content: content,
            trigger: trigger
        )
        let reminderDisplayName = preference.reminderType.displayName
        let reminderTime = preference.reminderTime
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error)")
            } else {
                print("Reminder scheduled: \(reminderDisplayName) at \(reminderTime)")
            }
        }
    }
    
    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.reminderNotificationIdentifier]
        )
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [Self.reminderNotificationIdentifier]
        )
    }

    func clearDeliveredReminderBadge() {
        let notificationCenter = UNUserNotificationCenter.current()

        notificationCenter.removeDeliveredNotifications(
            withIdentifiers: [Self.reminderNotificationIdentifier]
        )
        notificationCenter.setBadgeCount(0) { error in
            if let error = error {
                print("Error clearing reminder badge: \(error)")
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func createTrigger(from preference: ReminderPreference) -> UNNotificationTrigger {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: preference.reminderTime)
        
        let frequency = preference.frequency
        
        switch frequency {
        case .daily:
            var dailyComponents = DateComponents()
            dailyComponents.hour = components.hour
            dailyComponents.minute = components.minute
            return UNCalendarNotificationTrigger(dateMatching: dailyComponents, repeats: true)
            
        case .weekly:
            var weeklyComponents = DateComponents()
            weeklyComponents.weekday = preference.weekday.rawValue
            weeklyComponents.hour = components.hour
            weeklyComponents.minute = components.minute
            return UNCalendarNotificationTrigger(dateMatching: weeklyComponents, repeats: true)
            
        case .monthly:
            var monthlyComponents = DateComponents()
            monthlyComponents.day = preference.monthDay
            monthlyComponents.hour = components.hour
            monthlyComponents.minute = components.minute
            return UNCalendarNotificationTrigger(dateMatching: monthlyComponents, repeats: true)
        }
    }
}
