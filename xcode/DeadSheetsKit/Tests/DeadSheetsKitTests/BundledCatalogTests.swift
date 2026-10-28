import Foundation
import Testing

@testable import DeadSheetsKit

/// Checks the real `seeds.json` and the files the app bundles, which `pnpm xcode` generates.
struct BundledCatalogTests {
    let catalog = Catalog.bundled

    static let xcodeDirectory = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    /// Not on Apple Music, so they show a placeholder.
    static let albumsMissingFromAppleMusic: Set<Album.ID> = ["truckin-up-to-buffalo"]

    static func files(in folder: String, withExtension pathExtension: String) -> Set<String> {
        let contents = try? FileManager.default.contentsOfDirectory(
            atPath: xcodeDirectory.appending(path: folder).path(percentEncoded: false))
        return Set((contents ?? []).filter { $0.hasSuffix(".\(pathExtension)") })
    }

    @Test func loadsWithoutProblems() {
        #expect(!catalog.songs.isEmpty)
        #expect(catalog.problems == [])
    }

    @Test func everySongHasASheetAndCredits() {
        for song in catalog.songs {
            #expect(song.sheetFileName.hasSuffix(".pdf"), "\(song.id)")
            #expect(!song.credits.isEmpty, "\(song.id) has no writers")
            #expect(!song.lyrics.isEmpty, "\(song.id) has no lyrics")
        }
    }

    @Test func albumsAndArtistsHaveAppleMusicIDs() {
        for album in catalog.albums where !Self.albumsMissingFromAppleMusic.contains(album.id) {
            #expect(album.appleMusicID != nil, "\(album.id) has no Apple Music ID")
        }
        for artist in catalog.artists {
            #expect(artist.appleMusicID != nil, "\(artist.id) has no Apple Music ID")
        }
        for id in catalog.albumAppleMusicIDs + catalog.artistAppleMusicIDs {
            #expect(Int(id) != nil, "\(id) isn't an Apple Music catalog ID")
        }
    }

    @Test func schemaHasAScoreForEverySong() throws {
        let schema = try JSONDecoder().decode(
            [String: String].self,
            from: Data(contentsOf: Self.xcodeDirectory.appending(path: "Sheets/schema.json"))
        )
        let songIDs = Set(catalog.songs.map(\.id))
        #expect(songIDs.subtracting(schema.keys).sorted() == [], "songs without a score")
        #expect(Set(schema.keys).subtracting(songIDs).sorted() == [], "scores for songs that aren't in the catalog")
    }

    @Test func everySongHasAPDFAndNothingElseDoes() {
        let expected = Set(catalog.songs.map(\.sheetFileName))
        let pdfs = Self.files(in: "Sheets/pdfs", withExtension: "pdf")
        #expect(expected.subtracting(pdfs).sorted() == [], "missing from Sheets/pdfs")
        #expect(pdfs.subtracting(expected).sorted() == [], "in Sheets/pdfs but not in the catalog")
    }
}
