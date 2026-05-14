import UIKit
import UserNotifications

// MARK: - AppDelegate Extension for Reminder Module

extension UIApplicationDelegate {
    /// Call this from your AppDelegate.didFinishLaunchingWithOptions()
    /// or configure it in your Scene delegate
    static func setupReminderModule() {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
}

// MARK: - Alternative: SwiftUI Scene Modifier

import SwiftUI

struct ReminderModuleSetup: ViewModifier {
    @StateObject private var reminderManager = ReminderManager.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                configureNotifications()
            }
    }
    
    private func configureNotifications() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Optionally request permission on app launch
        // reminderManager.requestNotificationPermission()
    }
}

extension Scene {
    func setupReminders() -> some Scene {
        self
    }
}

// MARK: - Usage in SceneDelegate or AppDelegate

/*
 If using UISceneDelegate:
 
 func scene(
     _ scene: UIScene,
     willConnectTo session: UISceneSession,
     options connectionOptions: UIScene.ConnectionOptions
 ) {
     UIApplicationDelegate.setupReminderModule()
 }
 
 If using SwiftUI lifecycle:
 
 @main
 struct MyWealthApp: App {
     var body: some Scene {
         WindowGroup {
             ContentView()
                 .modifier(ReminderModuleSetup())
         }
     }
 }
 */
