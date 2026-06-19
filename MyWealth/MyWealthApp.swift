//
//  MyWealthApp.swift
//  MyWealth
//
//  Created by Biju Varghese on 11/7/25.
//

import SwiftUI
import SwiftData
import UserNotifications
#if os(iOS)
import UIKit
#endif

@main
struct MyWealthApp: App {
    @State private var containerHolder = ContainerHolder(isRunningTests: Self.isRunningTests)

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

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
            LaunchSplashContainer {
                AppRootView()
                    .setupReminderModule()
                    // Inject the holder so child views can trigger a container switch.
                    .environment(containerHolder)
                    // The modelContainer and .id are applied here so that when
                    // rebuildId changes the entire content tree re-mounts with the
                    // new container — no app restart needed.
                    .modelContainer(containerHolder.container)
                    .id(containerHolder.rebuildId)
            }
        }
    }
}

private struct LaunchSplashContainer<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowingSplash = true

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content

            if isShowingSplash {
                WealthMapSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            let delay = reduceMotion ? 900_000_000 : 2_350_000_000
            try? await Task.sleep(nanoseconds: UInt64(delay))

            withAnimation(.easeInOut(duration: reduceMotion ? 0.2 : 0.45)) {
                isShowingSplash = false
            }
        }
    }
}

private struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ContainerHolder.self) private var containerHolder
    @State private var settings = AppSettings()
    @State private var activityTracker = AppActivityTracker.shared

    private let iCloudSync = ICloudSettingsSync.shared

    var body: some View {
        Group {
            if settings.onboardingStatus().isComplete {
                if usesIPadLayout {
                    IPadRootView(settings: settings)
                } else {
                    AppTabView(settings: settings)
                }
            } else {
                OnboardingView(settings: settings)
            }
        }
        .onAppear {
            // One-time cleanup of duplicate snapshots created by the
            // now-fixed double-recording bug. Safe to call on every launch —
            // subsequent calls are instant no-ops once the flag is set.
            HistorySanitizer.sanitizeOnceIfNeeded(modelContext: modelContext)

            // Pull iCloud settings on launch, then keep listening for remote changes.
            if settings.iCloudSyncEnabled {
                iCloudSync.pull(into: settings)
                iCloudSync.startObserving {
                    Task { @MainActor in
                        iCloudSync.pull(into: settings)
                    }
                }
            }
        }
        // When the toggle changes, hot-swap the container immediately.
        .onChange(of: settings.iCloudSyncEnabled) { _, newValue in
            containerHolder.switchSync(enabled: newValue)
            // Start or stop KV sync accordingly.
            if newValue {
                iCloudSync.pull(into: settings)
                iCloudSync.startObserving {
                    Task { @MainActor in iCloudSync.pull(into: settings) }
                }
            } else {
                iCloudSync.stopObserving()
            }
        }
        .overlay(alignment: .top) {
            if containerHolder.iCloudAccountChanged {
                VStack(spacing: 0) {
                    Spacer().frame(height: 56)
                    HStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .foregroundStyle(.orange)
                        Text("iCloud account changed — data refreshed for the new account.")
                            .font(.footnote)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        containerHolder.clearAccountChangedFlag()
                    }
                }
            }
        }
        .animation(.easeInOut, value: containerHolder.iCloudAccountChanged)
        .overlay(alignment: .top) {
            if activityTracker.isActive {
                AppActivityBar()
                    .ignoresSafeArea(edges: .top)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: activityTracker.isActive)
        .onChange(of: settings.baseCurrency) {
            if settings.iCloudSyncEnabled { iCloudSync.push(settings: settings) }
        }
        .onChange(of: settings.totalCurrencies) {
            if settings.iCloudSyncEnabled { iCloudSync.push(settings: settings) }
        }
        .onChange(of: settings.usesCompactCurrencyTotals) {
            if settings.iCloudSyncEnabled { iCloudSync.push(settings: settings) }
        }
    }

    private var usesIPadLayout: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }
}

private struct AppTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
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

            BriefingView(settings: settings)
                .tabItem {
                    Label("Briefing", systemImage: "sparkles")
                }
        }
    }
}

private struct WealthMapSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    private let gold = Color(red: 212/255, green: 175/255, blue: 55/255)
    private let highlightGold = Color(red: 255/255, green: 224/255, blue: 130/255)
    private let charcoal = Color(red: 21/255, green: 21/255, blue: 21/255)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 250/255, green: 247/255, blue: 239/255),
                    Color(red: 245/255, green: 238/255, blue: 222/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .ignoresSafeArea()

            AnimatedWaveDotBackground(
                dotColor: gold.opacity(0.25),
                dotRadius: 1,
                spacing: 18
            )
                .ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(gold.opacity(0.22), lineWidth: 1)
                        .frame(width: 216, height: 216)

                    Circle()
                        .trim(from: 0.08, to: 0.42)
                        .stroke(
                            LinearGradient(
                                colors: [highlightGold.opacity(0.1), highlightGold, gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 216, height: 216)
                        .rotationEffect(.degrees(hasAppeared && !reduceMotion ? 330 : -35))
                        .opacity(hasAppeared ? 1 : 0)

                    Image("WealthMapCoin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 164, height: 164)
                        .shadow(color: gold.opacity(0.4), radius: 22, x: 0, y: 14)
                        .scaleEffect(hasAppeared && !reduceMotion ? 1 : 0.72)
                        .opacity(hasAppeared ? 1 : 0)
                }
                .animation(.spring(response: 0.72, dampingFraction: 0.72), value: hasAppeared)
                .animation(.easeOut(duration: 1.15), value: hasAppeared)

                VStack(spacing: 7) {
                    Text("Wealth Map")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(charcoal)

                    Text("Mapping your money clearly")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(charcoal.opacity(0.62))
                }
                .offset(y: hasAppeared && !reduceMotion ? 0 : 10)
                .opacity(hasAppeared ? 1 : 0)
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(.easeOut(duration: reduceMotion ? 0.2 : 0.55)) {
                hasAppeared = true
            }
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
