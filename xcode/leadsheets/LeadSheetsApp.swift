import SwiftUI
import SwiftData

@main
struct LeadSheetsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Song.self, Artist.self, Album.self, Singer.self])
    }
}
