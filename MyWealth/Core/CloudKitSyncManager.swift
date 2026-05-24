import SwiftData
import CloudKit
import Observation

/// Builds the SwiftData ModelContainer, switching between a local-only store
/// and a CloudKit-backed store depending on the user's iCloud sync preference.
///
/// Prerequisites (manual Xcode step before this code is active):
///   Target → Signing & Capabilities → add iCloud → check CloudKit + Key-value storage.
enum CloudKitSyncManager {

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

        if syncEnabled {
            // CloudKit private database — data lives in the user's personal iCloud account.
            // SwiftData auto-generates the CloudKit schema on first launch.
            // The Simulator has no real CloudKit access, so fall back to local storage there
            // while still allowing the sync toggle UI to be exercised during development.
            #if targetEnvironment(simulator)
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .automatic
            )
            #else
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            #endif
            return try ModelContainer(for: schema, configurations: [config])
        } else {
            // Local-only store (existing behaviour).
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .automatic
            )
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

    init(isRunningTests: Bool) {
        let syncEnabled = UserDefaults.standard.bool(forKey: "settings.iCloudSyncEnabled")
        do {
            container = try CloudKitSyncManager.makeContainer(
                syncEnabled: syncEnabled,
                isRunningTests: isRunningTests
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// Swaps to a new container with the given sync setting.
    /// Both local-only and CloudKit-backed configs use the same SQLite file,
    /// so all existing data is immediately available in the new container.
    @MainActor
    func switchSync(enabled: Bool) {
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
}
