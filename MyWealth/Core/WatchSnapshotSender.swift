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
        guard
            let session,
            session.isWatchAppInstalled,
            let context = Self.context(for: snapshot)
        else { return }

        if session.activationState != .activated {
            session.activate()
        }

        try? session.updateApplicationContext(context)

        if session.isReachable {
            session.sendMessage(context, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(context)
        }
    }

    private static func context(for snapshot: WidgetSnapshot) -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(snapshot) else { return nil }
        return ["snapshot": data]
    }

    private static func savedSnapshotContext() -> [String: Any]? {
        guard let snapshot = WidgetDataStore.load() else { return nil }
        return context(for: snapshot)
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard
            activationState == .activated,
            session.isWatchAppInstalled,
            let context = Self.savedSnapshotContext()
        else { return }

        try? session.updateApplicationContext(context)
    }

    func session(
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
        if session.isWatchAppInstalled {
            try? session.updateApplicationContext(context)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
#endif
