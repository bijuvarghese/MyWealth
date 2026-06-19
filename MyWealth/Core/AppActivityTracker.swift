import Foundation
import Observation

/// Tracks overlapping app-wide loading and sync work for the global activity bar.
@Observable
@MainActor
final class AppActivityTracker {
    static let shared = AppActivityTracker()

    private(set) var isActive = false

    private var activityIDs: Set<UUID> = []
    private var pendingHide: Task<Void, Never>?

    private init() {}

    @discardableResult
    func begin() -> UUID {
        let id = UUID()
        activityIDs.insert(id)
        pendingHide?.cancel()
        pendingHide = nil
        isActive = true
        return id
    }

    func end(_ id: UUID) {
        activityIDs.remove(id)
        guard activityIDs.isEmpty else { return }

        pendingHide?.cancel()
        pendingHide = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled, let self, self.activityIDs.isEmpty else { return }
            self.isActive = false
            self.pendingHide = nil
        }
    }
}
