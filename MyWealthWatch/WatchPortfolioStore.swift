import Foundation
import Combine
import WatchConnectivity

@MainActor
final class WatchPortfolioStore: NSObject, ObservableObject, @preconcurrency WCSessionDelegate {
    @Published private(set) var snapshot: WatchPortfolioSnapshot
    @Published private(set) var connectionStatus = "Waiting for iPhone"

    private static let snapshotKey = "watch.portfolioSnapshot"

    override init() {
        snapshot = Self.loadSnapshot() ?? .placeholder
        super.init()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else {
            connectionStatus = "WatchConnectivity unavailable"
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        syncSnapshot(from: session)
    }

    private func updateSnapshot(from context: [String: Any]) {
        guard
            let data = context["snapshot"] as? Data,
            let snapshot = try? JSONDecoder().decode(WatchPortfolioSnapshot.self, from: data)
        else { return }

        self.snapshot = snapshot
        self.connectionStatus = "Updated from iPhone"
        Self.save(snapshot)
    }

    private func requestSnapshot(from session: WCSession = .default) {
        guard session.activationState == .activated else { return }

        guard session.isReachable else {
            connectionStatus = "Open Wealth Map on iPhone"
            return
        }

        session.sendMessage(
            ["requestSnapshot": true],
            replyHandler: { [weak self] reply in
                Task { @MainActor in
                    guard let self else { return }
                    if reply["snapshot"] != nil {
                        self.updateSnapshot(from: reply)
                    } else {
                        self.connectionStatus = "No iPhone snapshot yet"
                    }
                }
            },
            errorHandler: { [weak self] _ in
                Task { @MainActor in
                    self?.connectionStatus = "Open Wealth Map on iPhone"
                }
            }
        )
    }

    private func syncSnapshot(from session: WCSession) {
        guard session.activationState == .activated else { return }

        if !session.receivedApplicationContext.isEmpty {
            updateSnapshot(from: session.receivedApplicationContext)
        } else {
            requestSnapshot(from: session)
        }
    }

    private static func save(_ snapshot: WatchPortfolioSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: snapshotKey)
    }

    private static func loadSnapshot() -> WatchPortfolioSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WatchPortfolioSnapshot.self, from: data)
    }
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        self.connectionStatus = activationState == .activated
            ? "Connected to iPhone"
            : "Waiting for iPhone"

        syncSnapshot(from: session)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        updateSnapshot(from: applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        updateSnapshot(from: userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        updateSnapshot(from: message)
    }
}
