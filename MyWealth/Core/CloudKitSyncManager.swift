import SwiftData
import CloudKit
import Observation

/// Builds the SwiftData ModelContainer, switching between a local-only store
/// and a CloudKit-backed store depending on the user's iCloud sync preference.
///
/// Prerequisites (manual Xcode step before this code is active):
///   Target → Signing & Capabilities → add iCloud → check CloudKit + Key-value storage.
enum CloudKitSyncManager {

    /// Explicit store URL that matches SwiftData's default path.
    /// The earlier error log confirmed CloudKit uses Library/Application Support/default.store,
    /// so we pin every non-CloudKit config to the same file to guarantee they share one store.
    /// (groupContainer: .automatic was removed because no App Group entitlement exists —
    /// without one its resolution is undefined and it may silently create a separate SQLite file.)
    static var localStoreURL: URL {
        URL.applicationSupportDirectory.appending(path: "default.store")
    }

    static func makeContainer(syncEnabled: Bool, isRunningTests: Bool) throws -> ModelContainer {
        let schema = Schema([
            Asset.self,
            Liability.self,
            AssetValueSnapshot.self,
            NetWorthSnapshot.self,
            PortfolioSnapshot.self,
        ])

        // Always use in-memory for unit tests.
        if isRunningTests {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
        }

        if syncEnabled, ICloudSettingsSync.isAvailable {
            // CloudKit private database — data lives in the user's personal iCloud account.
            // SwiftData auto-generates the CloudKit schema on first launch.
            // The Simulator has no real CloudKit access, so fall back to local storage there
            // while still allowing the sync toggle UI to be exercised during development.
            #if targetEnvironment(simulator)
            let config = ModelConfiguration(schema: schema, url: localStoreURL)
            #else
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            #endif
            return try ModelContainer(for: schema, configurations: [config])
        } else {
            // Local-only: explicit URL so this config and the CloudKit-backed config
            // always read/write the same SQLite file — switching sync on/off is seamless.
            let config = ModelConfiguration(schema: schema, url: localStoreURL)
            return try ModelContainer(for: schema, configurations: [config])
        }
    }
}

// MARK: - Container Holder

/// Owns the active ModelContainer and exposes a `rebuildId` that changes
/// whenever the container is swapped. Views observe this to force a full
/// re-mount of the SwiftData-backed subtree — no app restart required.
@Observable
final class ContainerHolder {

    private(set) var container: ModelContainer
    /// Changes every time the container is swapped. Use as `.id(holder.rebuildId)`
    /// on the root content view to trigger a full subtree rebuild.
    private(set) var rebuildId: UUID = UUID()
    /// Set to true when CloudKit detects the iCloud account changed mid-session.
    /// The UI can observe this to show an informative banner.
    private(set) var iCloudAccountChanged: Bool = false

    init(isRunningTests: Bool) {
        let syncEnabled = UserDefaults.standard.bool(forKey: "settings.iCloudSyncEnabled")
        do {
            container = try CloudKitSyncManager.makeContainer(
                syncEnabled: syncEnabled,
                isRunningTests: isRunningTests
            )
            let storeURL = container.configurations.first?.url.absoluteString ?? "unknown"
            print("[MyWealth] SwiftData store URL: \(storeURL)")
            print("[MyWealth] iCloud sync enabled: \(syncEnabled)")
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        // Selector-based registration: no token is returned, so there is nothing
        // to store and no deinit / nonisolated(unsafe) dance is needed.
        // ContainerHolder is a long-lived singleton, so not removing the observer
        // is safe — it will simply be collected with the process.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAccountChange),
            name: .NSUbiquityIdentityDidChange,
            object: nil
        )
    }

    /// Resets the account-changed flag after the banner has been shown.
    @MainActor
    func clearAccountChangedFlag() {
        iCloudAccountChanged = false
    }

    /// Swaps to a new container with the given sync setting.
    /// Both local-only and CloudKit-backed configs use the same SQLite file,
    /// so all existing data is immediately available in the new container.
    @MainActor
    func switchSync(enabled: Bool) {
        let activityID = AppActivityTracker.shared.begin()
        defer { AppActivityTracker.shared.end(activityID) }

        do {
            container = try CloudKitSyncManager.makeContainer(
                syncEnabled: enabled,
                isRunningTests: false
            )
            rebuildId = UUID()
        } catch {
            // If the switch fails, revert the preference so the toggle stays consistent.
            UserDefaults.standard.set(!enabled, forKey: "settings.iCloudSyncEnabled")
        }
    }

    // MARK: - iCloud Account Change Handling

    /// Called by NotificationCenter when the iCloud account changes.
    /// Hops to the main actor before touching any @Observable state.
    @objc private func onAccountChange() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let activityID = AppActivityTracker.shared.begin()
            defer { AppActivityTracker.shared.end(activityID) }

            iCloudAccountChanged = true
            let syncEnabled = UserDefaults.standard.bool(forKey: "settings.iCloudSyncEnabled")
            do {
                container = try CloudKitSyncManager.makeContainer(
                    syncEnabled: syncEnabled,
                    isRunningTests: false
                )
                rebuildId = UUID()
            } catch {
                UserDefaults.standard.set(false, forKey: "settings.iCloudSyncEnabled")
            }
        }
    }
}
