import DeadSheetsKit
import SwiftUI

@main
struct LeadSheetsWatchApp: App {
    init() {
        LegacyStoreCleanup.run()
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
