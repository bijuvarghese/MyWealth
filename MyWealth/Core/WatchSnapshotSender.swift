import Foundation
import WatchConnectivity

#if os(iOS)
final class WatchSnapshotSender: NSObject, @unchecked Sendable, WCSessionDelegate {
    static let shared = WatchSnapshotSender()

    private let session: WCSession?

    private override init() {
        if WCSession.isSupported() {
            session = .default
        } else {
            session = nil
        }
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func send(_ snapshot: WidgetSnapshot) {
        guard let session, let context = Self.context(for: snapshot) else { return }

        guard session.activationState == .activated else {
            session.activate()
            return
        }

        guard
            session.isPaired,
            session.isWatchAppInstalled,
            session.activationState == .activated
        else { return }

        try? session.updateApplicationContext(context)

        if session.isReachable {
            session.sendMessage(context, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(context)
        }
    }

    private nonisolated static func context(for snapshot: WidgetSnapshot) -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(snapshot) else { return nil }
        return ["snapshot": data]
    }

    private nonisolated static func savedSnapshotContext() -> [String: Any]? {
        guard let snapshot = WidgetDataStore.load() else { return nil }
        return context(for: snapshot)
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard
            activationState == .activated,
            session.isPaired,
            session.isWatchAppInstalled,
            let context = Self.savedSnapshotContext()
        else { return }

        try? session.updateApplicationContext(context)
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message["requestSnapshot"] as? Bool == true else {
            replyHandler([:])
            return
        }

        guard let context = Self.savedSnapshotContext() else {
            replyHandler([:])
            return
        }

        replyHandler(context)
        if session.activationState == .activated, session.isPaired, session.isWatchAppInstalled {
            try? session.updateApplicationContext(context)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
#endif
