import SwiftUI

@main
struct MyWealthWatchApp: App {
    @StateObject private var store = WatchPortfolioStore()

    var body: some Scene {
        WindowGroup {
            WatchDashboardView(store: store)
        }
    }
}
