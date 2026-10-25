#if os(iOS) || os(macOS)
import DeadSheetsKit
import Foundation
import os
import SwiftData

// Keyed by song slug, so updating seeds.json never loses them. No unique constraints and a default
// for every property keep the models compatible with CloudKit sync.

@Model
final class Favorite {
    var songID: Song.ID = ""
    var addedAt = Date.now

    init(songID: Song.ID) {
        self.songID = songID
    }
}

@Model
final class Setlist {
    var name = ""
    /// In playing order.
    var songIDs: [Song.ID] = []
    var createdAt = Date.now

    init(name: String, songIDs: [Song.ID] = []) {
        self.name = name
        self.songIDs = songIDs
    }
}

enum UserData {
    static let container: ModelContainer = {
        let schema = Schema([Favorite.self, Setlist.self])
        // UI tests start from an empty library each time.
        let inMemory = ProcessInfo.processInfo.arguments.contains("-inMemoryUserData")
        do {
            return try ModelContainer(
                for: schema,
                configurations: ModelConfiguration("UserData", schema: schema, isStoredInMemoryOnly: inMemory)
            )
        } catch {
            Logger.userData.fault("Couldn't open the user data store: \(error.localizedDescription, privacy: .public)")
            do {
                return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            } catch {
                fatalError("Couldn't create an in-memory store: \(error)")
            }
        }
    }()
}
#endif
