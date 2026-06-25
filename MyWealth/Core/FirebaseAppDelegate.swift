import Foundation

#if os(iOS)
import UIKit
#endif

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if os(iOS)
final class FirebaseAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseBootstrap.configureIfPossible()
        return true
    }
}
#endif

enum FirebaseBootstrap {
    static func configureIfPossible() {
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() == nil else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            #if DEBUG
            debugPrint("Firebase not configured: GoogleService-Info.plist is not bundled.")
            #endif
            return
        }
        FirebaseApp.configure()
        #endif
    }
}
