import Foundation
import Testing

@testable import DeadSheetsKit

struct MultiArtistCatalogTests {
    @Test func sameTitlesKeepTheirArtistAndAlbumRelationships() throws {
        let catalog = try makeCatalog()
        #expect(catalog.problems.isEmpty)
        #expect(catalog.songs.map(\.id) == ["harbor-home", "harbor-live-home", "northbound-home"])
        #expect(catalog.songs.allSatisfy { $0.title == "Home" })
        #expect(catalog.albums.map(\.id) == ["harbor-hits", "northbound-hits", "harbor-live"])
        let harbor = try #require(catalog.artist(id: "harbor"))
        let northbound = try #require(catalog.artist(id: "northbound"))
        #expect(catalog.songs(by: harbor).map(\.id) == ["harbor-home", "harbor-live-home"])
        #expect(catalog.songs(by: northbound).map(\.id) == ["northbound-home"])
        let hits = try #require(catalog.album(id: "northbound-hits"))
        #expect(catalog.songs(on: hits).map(\.id) == ["northbound-home"])
    }

    @Test func descriptionsIdentifyEveryArtistRegardlessOfCatalogSize() throws {
        let catalog = try makeCatalog()
        #expect(catalog.song(id: "harbor-home")?.artistAndAlbum == "Harbor Trio · Greatest Hits")
        #expect(catalog.song(id: "northbound-home")?.artistAndAlbum == "Northbound · Greatest Hits")
    }

    @Test func searchCanDisambiguateAnArtistAndTitleTogether() throws {
        let catalog = try makeCatalog()
        #expect(catalog.songs(matching: "northbound home").map(\.id) == ["northbound-home"])
        #expect(catalog.songs(matching: "  HÁRBOR home  ").map(\.id) == ["harbor-home", "harbor-live-home"])
        #expect(catalog.songs(matching: "harbor live").map(\.id) == ["harbor-live-home"])
        #expect(catalog.albums(matching: "northbound hits").map(\.id) == ["northbound-hits"])
        #expect(catalog.covers(matching: "northbound hits").map(\.id) == ["northbound-home"])
        #expect(catalog.songs(matching: " \n ").map(\.id) == catalog.songs.map(\.id))
    }

    @Test func lyricsCreditsAndAppleMusicAreOptional() throws {
        let catalog = try makeCatalog()
        let song = try #require(catalog.song(id: "northbound-home"))
        #expect(catalog.problems.isEmpty)
        #expect(song.lyrics.isEmpty)
        #expect(song.creditsText == "Unknown Writer")
        #expect(song.singer == nil)
        #expect(song.appleMusicID == nil)
        #expect(catalog.albumAppleMusicIDs.isEmpty)
        #expect(catalog.artistAppleMusicIDs.isEmpty)
    }

    @Test func artistsWithTheSameNameKeepDistinctStableIDs() throws {
        let catalog = try makeCatalog(seeds: Self.seeds.replacingOccurrences(of: "Northbound", with: "Harbor Trio"))
        #expect(catalog.problems.isEmpty)
        #expect(catalog.artists.map(\.name) == ["Harbor Trio", "Harbor Trio"])
        #expect(catalog.artists.map(\.id) == ["harbor", "northbound"])
    }

    @Test func duplicateArtistIDsAreReportedInsteadOfCrashing() throws {
        let catalog = try makeCatalog(seeds: Self.seeds.replacingOccurrences(of: "\"slug\": \"northbound\"", with: "\"slug\": \"harbor\""))
        #expect(catalog.problems == ["Artist harbor appears more than once"])
        #expect(catalog.artists.count == 1)
        #expect(catalog.songs.map(\.id) == ["northbound-home"])
    }

    @Test func duplicateAlbumIDsCannotMixSongsFromDifferentArtists() throws {
        let catalog = try makeCatalog(
            seeds: Self.seeds.replacingOccurrences(of: "\"slug\": \"northbound-hits\"", with: "\"slug\": \"harbor-hits\""))
        #expect(catalog.problems == ["Album harbor-hits appears more than once"])
        #expect(catalog.album(id: "harbor-hits")?.artistID == "northbound")
        #expect(catalog.artist(id: "harbor")?.albumIDs == ["harbor-live"])
        #expect(catalog.song(id: "harbor-home") == nil)
    }

    @Test func recordingSlugsMustStillBeGloballyUnique() throws {
        let catalog = try makeCatalog(
            seeds: Self.seeds.replacingOccurrences(of: "\"slug\": \"northbound-home\"", with: "\"slug\": \"harbor-home\""))
        #expect(catalog.problems == ["Song harbor-home appears more than once"])
        #expect(catalog.song(id: "harbor-home")?.artistID == "northbound")
        #expect(catalog.artist(id: "harbor")?.songIDs == ["harbor-live-home"])
    }

    private func makeCatalog(seeds: String = Self.seeds) throws -> Catalog {
        try Catalog(seedData: Data(seeds.utf8))
    }

    private static let seeds = """
        {
          "artists": [
            {
              "name": "Northbound", "slug": "northbound",
              "albums": [{
                "name": "Greatest Hits", "slug": "northbound-hits",
                "songs": [{"name": "Home", "slug": "northbound-home", "fileName": "Northbound Home.pdf", "songType": "cover"}]
              }]
            },
            {
              "name": "Harbor Trio", "slug": "harbor",
              "albums": [
                {
                  "name": "Live", "slug": "harbor-live",
                  "songs": [{"name": "Home", "slug": "harbor-live-home", "fileName": "Harbor Home Live.pdf"}]
                },
                {
                  "name": "Greatest Hits", "slug": "harbor-hits",
                  "songs": [{"name": "Home", "slug": "harbor-home", "fileName": "Harbor Home.pdf"}]
                }
              ]
            }
          ],
          "singers": [],
          "writers": []
        }
        """
}
