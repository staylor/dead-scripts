#if os(iOS) || os(macOS)
import AppIntents
import CoreSpotlight
import DeadSheetsKit
import Foundation
import Observation
import os

struct SongEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Song"
    static let defaultQuery = SongQuery()

    let id: Song.ID
    let title: String
    let subtitle: String

    init(_ song: Song) {
        id = song.id
        title = song.title
        subtitle = "\(song.albumTitle) · \(song.creditsText)"
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(subtitle)", image: .init(systemName: "music.note"))
    }
}

struct SongQuery: EntityStringQuery {
    func entities(for identifiers: [SongEntity.ID]) async throws -> [SongEntity] {
        identifiers.compactMap(Catalog.bundled.song(id:)).map(SongEntity.init)
    }

    func entities(matching string: String) async throws -> [SongEntity] {
        Catalog.bundled.songs(matching: string).map(SongEntity.init)
    }

    func suggestedEntities() async throws -> [SongEntity] {
        Catalog.bundled.songs.map(SongEntity.init)
    }
}

struct OpenSongIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Song"
    static let description = IntentDescription("Shows a song’s lead sheet.")

    @Parameter(title: "Song")
    var target: SongEntity

    func perform() async throws -> some IntentResult {
        await SongRequests.shared.open(target.id)
        return .result()
    }
}

struct DeadSheetsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenSongIntent(),
            phrases: [
                "Open \(\.$target) in \(.applicationName)",
                "Show the lead sheet for \(\.$target) in \(.applicationName)",
                "Open a song in \(.applicationName)",
            ],
            shortTitle: "Open Song",
            systemImageName: "music.note"
        )
    }
}

/// Songs the system asked the app to show (from Shortcuts, Siri or Spotlight), for the window to pick up.
@MainActor
@Observable
final class SongRequests {
    static let shared = SongRequests()

    var pendingSongID: Song.ID?

    func open(_ songID: Song.ID) {
        pendingSongID = songID
    }
}

enum SongIndex {
    /// Tells Siri which songs the App Shortcut phrases can name, and Spotlight about every song.
    static func update() async {
        DeadSheetsShortcuts.updateAppShortcutParameters()
        do {
            try await CSSearchableIndex.default().indexAppEntities(Catalog.bundled.songs.map(SongEntity.init))
        } catch {
            Logger.catalog.error("Couldn't index songs for Spotlight: \(error.localizedDescription, privacy: .public)")
        }
    }
}
#endif

#if os(iOS) || os(macOS)
/// Handoff for the open song.
enum SongActivity {
    static let type = "wonderboymusic.leadsheets.song"
    static let songIDKey = "songID"
}
#endif
