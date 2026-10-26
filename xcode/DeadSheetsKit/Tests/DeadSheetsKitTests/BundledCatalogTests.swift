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

    static func exists(_ relativePath: String) -> Bool {
        FileManager.default.fileExists(atPath: xcodeDirectory.appending(path: relativePath).path(percentEncoded: false))
    }

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

    @Test func albumCoversExist() {
        for album in catalog.albums {
            guard let cover = album.coverFileName else {
                Issue.record("\(album.id) has no cover")
                continue
            }
            #expect(Self.exists("leadsheets/Resources/albums/\(cover)"), "albums/\(cover) is missing")
        }
    }

    @Test func artistAndSingerPhotosExist() {
        let photos = catalog.artists.compactMap(\.imageFileName) + catalog.singers.compactMap(\.imageFileName)
        for photo in photos {
            #expect(Self.exists("leadsheets/Resources/artists/\(photo)"), "artists/\(photo) is missing")
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

    @Test func everySongHasATVImageAndNothingElseDoes() {
        let expected = Set(catalog.songs.map { ($0.sheetFileName as NSString).deletingPathExtension + ".png" })
        let images = Self.files(in: "Sheets/images", withExtension: "png")
        #expect(expected.subtracting(images).sorted() == [], "missing from Sheets/images")
        #expect(images.subtracting(expected).sorted() == [], "in Sheets/images but not in the catalog")
    }
}
