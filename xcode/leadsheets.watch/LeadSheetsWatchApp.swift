import DeadSheetsKit
import SwiftUI

@main
struct LeadSheetsWatchApp: App {
    init() {
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
