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
    /// Stable from creation, unlike `persistentModelID`, which changes when a new model is first saved.
    var id = UUID()
    var name = ""
    /// In playing order.
    var songIDs: [Song.ID] = []
    var createdAt = Date.now

    init(name: String, songIDs: [Song.ID] = []) {
        self.name = name
        self.songIDs = songIDs
    }
}

struct UserData {
    let container: ModelContainer
    let isAvailable: Bool

    static let shared: UserData = {
        let arguments = ProcessInfo.processInfo.arguments
        do {
            return try UserData(isStoredInMemoryOnly: arguments.contains("-inMemoryUserData")) { configuration in
                #if DEBUG
                if arguments.contains("-unavailableUserData"), !configuration.isStoredInMemoryOnly {
                    throw CocoaError(.fileReadCorruptFile)
                }
                #endif
                return try ModelContainer(for: schema, configurations: configuration)
            }
        } catch {
            fatalError("Couldn't create an in-memory store: \(error)")
        }
    }()

    static let schema = Schema([Favorite.self, Setlist.self])

    init(
        isStoredInMemoryOnly: Bool = false,
        url: URL? = nil,
        makeContainer: (ModelConfiguration) throws -> ModelContainer = {
            try ModelContainer(for: schema, configurations: $0)
        }
    ) throws {
        let configuration =
            if let url {
                ModelConfiguration("UserData", schema: Self.schema, url: url, cloudKitDatabase: .none)
            } else {
                ModelConfiguration(
                    "UserData", schema: Self.schema, isStoredInMemoryOnly: isStoredInMemoryOnly, cloudKitDatabase: .none
                )
            }
        do {
            container = try makeContainer(configuration)
            isAvailable = true
        } catch {
            Logger.userData.fault("Couldn't open the user data store: \(error.localizedDescription, privacy: .public)")
            container = try makeContainer(
                ModelConfiguration(schema: Self.schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            )
            isAvailable = false
        }
        container.mainContext.autosaveEnabled = false
    }

    func save(
        in context: ModelContext,
        restoring setlists: [Setlist] = [],
        using persist: (ModelContext) throws -> Void = { try $0.save() },
        _ changes: () -> Void
    ) -> SaveFailure? {
        guard isAvailable else { return SaveFailure() }
        let originalSongs = setlists.map { ($0, $0.songIDs) }
        changes()
        do {
            try persist(context)
            return nil
        } catch {
            // iOS 26 leaves array-valued attributes cached after rollback.
            for (setlist, songIDs) in originalSongs {
                setlist.songIDs = songIDs
            }
            context.rollback()
            Logger.userData.error("Couldn't save user data: \(error.localizedDescription, privacy: .public)")
            return SaveFailure()
        }
    }

    struct SaveFailure: LocalizedError {
        var errorDescription: String? { "Couldn’t Save Changes" }
        var failureReason: String? {
            "Your changes weren’t saved and have been undone. Please try again. If the problem continues, restart Dead Sheets."
        }
    }
}
#endif
