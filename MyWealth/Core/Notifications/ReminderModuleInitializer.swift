import SwiftUI

/// App initialization modifier that sets up notification handling
struct ReminderModuleInitializer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                setupNotificationDelegate()
            }
    }
}

extension View {
    func setupReminderModule() -> some View {
        modifier(ReminderModuleInitializer())
    }
}

private func setupNotificationDelegate() {
    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
}
