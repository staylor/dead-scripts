import Foundation
import Testing

@testable import DeadSheetsKit

struct ArtworkRequestTests {
    @Test func largeCatalogsStayWithinBothAppleMusicLimits() throws {
        let catalog = try makeCatalog(artistCount: 60, albumsPerArtist: 4)
        let albums = catalog.artworkRequests.filter { $0.kind == .albums }
        let artists = catalog.artworkRequests.filter { $0.kind == .artists }
        #expect(albums.map { $0.ids.count } == [100, 100, 40])
        #expect(artists.map { $0.ids.count } == [25, 25, 10])
        #expect(albums.flatMap(\.ids) == catalog.albumAppleMusicIDs)
        #expect(artists.flatMap(\.ids) == catalog.artistAppleMusicIDs)
    }

    @Test func emptyCatalogsDoNotMakeEmptyRequests() throws {
        #expect(try makeCatalog(artistCount: 0, albumsPerArtist: 0).artworkRequests.isEmpty)
    }

    @Test func sharedResourceIDsAreRequestedOnlyOnce() throws {
        let catalog = try makeCatalog(artistCount: 40, albumsPerArtist: 4, shareIDs: true)
        let albums = catalog.artworkRequests.filter { $0.kind == .albums }
        let artists = catalog.artworkRequests.filter { $0.kind == .artists }
        #expect(albums.flatMap(\.ids) == ["1000"])
        #expect(artists.flatMap(\.ids) == ["1"])
    }

    @Test func batchesAreStableWhenArtistInputOrderChanges() throws {
        let forward = try makeCatalog(artistCount: 30, albumsPerArtist: 4)
        let reverse = try makeCatalog(artistCount: 30, albumsPerArtist: 4, reversed: true)
        #expect(forward.artworkRequests == reverse.artworkRequests)
    }

    @Test func onlyResourcesWithAnIDAreRequested() {
        #expect(Fixtures.catalog.artworkRequests.flatMap(\.ids).sorted() == ["10", "20", "30", "31"])
        #expect(Fixtures.catalog.artworkRequests.allSatisfy { !$0.ids.isEmpty })
    }

    private func makeCatalog(
        artistCount: Int, albumsPerArtist: Int, shareIDs: Bool = false, reversed: Bool = false
    ) throws -> Catalog {
        var artists: [[String: Any]] = (0..<artistCount).map { artist in
            [
                "name": "Artist \(artist)", "slug": "artist-\(artist)",
                "appleMusicId": shareIDs ? "1" : String(artist + 1),
                "albums": (0..<albumsPerArtist).map { album in
                    [
                        "name": "Album \(album)", "slug": "artist-\(artist)-album-\(album)",
                        "appleMusicId": shareIDs ? "1000" : String(1000 + artist * albumsPerArtist + album),
                    ]
                },
            ]
        }
        if reversed { artists.reverse() }
        let data = try JSONSerialization.data(withJSONObject: ["artists": artists, "singers": [], "writers": []])
        return try Catalog(seedData: data)
    }
}
