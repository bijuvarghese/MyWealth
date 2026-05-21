//
//  MyWealthApp.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//

import SwiftUI
import SwiftData

@main
struct MyWealthApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Asset.self,
            AssetValueSnapshot.self,
            NetWorthSnapshot.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: Self.isRunningTests,
            groupContainer: ModelConfiguration.GroupContainer.automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private static var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        let arguments = ProcessInfo.processInfo.arguments

        return environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestBundlePath"] != nil
            || environment["XCInjectBundleInto"] != nil
            || arguments.contains { argument in
                argument.contains("XCTest") || argument.contains(".xctest")
            }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .setupReminderModule()
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct AppRootView: View {
    @State private var settings = AppSettings()

    var body: some View {
        if settings.onboardingStatus().isComplete {
            TabView {
                DashboardView(settings: settings)
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.pie.fill")
                    }

                AssetListView()
                    .tabItem {
                        Label("Assets", systemImage: "list.bullet.rectangle")
                    }

                TransferRatesView(settings: settings)
                    .tabItem {
                        Label("Rates", systemImage: "arrow.left.arrow.right.circle.fill")
                    }

                SettingsView(settings: settings, showsDoneButton: false)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
        } else {
            OnboardingView(settings: settings)
        }
    }
}
