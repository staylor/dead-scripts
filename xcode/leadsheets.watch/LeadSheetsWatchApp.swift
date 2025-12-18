import SwiftUI
import SwiftData
import WatchConnectivity

@main
struct LeadSheetsWatchApp: App {
    init() {
        // Initialize Watch Connectivity early
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Song.self, Artist.self, Album.self, Singer.self, Writer.self])
    }
}
