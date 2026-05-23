//
//  MyWealthApp.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct MyWealthApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Asset.self,
            Liability.self,
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

                AssetListView(settings: settings)
                    .tabItem {
                        Label("Assets", systemImage: "list.bullet.rectangle")
                    }

                NetWorthView(settings: settings)
                    .tabItem {
                        Label("Net Worth", systemImage: "chart.line.uptrend.xyaxis")
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

private struct AnimatedDotLaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            AnimatedWaveDotBackground(dotRadius: 1.2, spacing: 20)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image("launchImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 104)
                    .scaleEffect(isAnimating && !reduceMotion ? 1.04 : 0.96)
                    .animation(
                        .easeInOut(duration: 0.75)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.accent)
                            .frame(width: 9, height: 9)
                            .scaleEffect(isAnimating && !reduceMotion ? 1.12 : 0.86)
                            .offset(y: isAnimating && !reduceMotion ? -6 : 6)
                            .opacity(isAnimating && !reduceMotion ? 1 : 0.55)
                            .animation(
                                .easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.12),
                                value: isAnimating
                            )
                    }
                }
            }
            .padding(22)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .onAppear {
            isAnimating = true
        }
    }
}

private struct AnimatedWaveDotBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var dotColor: Color = Color(red: 166/255, green: 23/255, blue: 142/255)
    var dotRadius: CGFloat = 1
    var spacing: CGFloat = 16

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                let circle = Path(
                    ellipseIn: CGRect(
                        x: -dotRadius,
                        y: -dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                )

                for y in stride(from: 0.0, through: size.height + spacing, by: spacing) {
                    for x in stride(from: 0.0, through: size.width + spacing, by: spacing) {
                        let phase = (x / 34) + (y / 48) + (time * 4)
                        let waveOffset = CGFloat(sin(phase)) * 5
                        let opacity = 0.45 + (sin(phase) * 0.25)

                        var dotContext = context
                        dotContext.translateBy(x: x, y: y + waveOffset)
                        dotContext.opacity = opacity
                        dotContext.fill(circle, with: .color(dotColor))
                    }
                }
            }
        }
    }
}
