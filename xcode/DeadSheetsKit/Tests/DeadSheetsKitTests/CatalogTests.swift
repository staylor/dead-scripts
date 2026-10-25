import Foundation
import Testing
@testable import DeadSheetsKit

struct CatalogTests {
    let catalog = Fixtures.catalog

    @Test func songsAreSortedByTitle() {
        #expect(catalog.songs.map(\.title) == [
            "Big Boss Man", "Box of Rain", "Friend of the Devil", "Morning Dew", "Ripple", "Sugaree",
        ])
    }

    @Test func albumSongsFollowTrackOrder() throws {
        let album = try #require(catalog.album(id: "american-beauty"))
        #expect(catalog.songs(on: album).map(\.id) == ["box-of-rain", "friend-of-the-devil", "ripple"])
    }

    @Test func songsCarryTheirAlbumAndArtist() {
        let ripple = Fixtures.song("ripple")
        #expect(ripple.albumTitle == "American Beauty")
        #expect(ripple.albumReleaseYear == 1970)
        #expect(ripple.coverFileName == "american-beauty.jpg")
        #expect(ripple.artistName == "Grateful Dead")
        #expect(ripple.singer?.name == "Jerry Garcia")
        #expect(ripple.singer?.imageFileName == "jerry-garcia.jpg")
    }

    @Test func artistIDFallsBackToASlugOfTheName() {
        #expect(catalog.artists.map(\.id) == ["grateful-dead", "jerry-garcia"])
    }

    @Test func artistsListTheirAlbumsAndSongs() throws {
        let garcia = try #require(catalog.artist(id: "jerry-garcia"))
        #expect(garcia.albumIDs == ["garcia"])
        #expect(catalog.songs(by: garcia).map(\.id) == ["sugaree"])
    }

    @Test func emptyAppleMusicIDsAreTreatedAsMissing() {
        #expect(Fixtures.song("ripple").appleMusicID == "1")
        #expect(Fixtures.song("morning-dew").appleMusicID == nil)
        #expect(Fixtures.song("friend-of-the-devil").appleMusicID == nil)
    }

    @Test func coversAreFlagged() {
        #expect(catalog.songs.filter(\.isCover).map(\.id) == ["big-boss-man", "morning-dew"])
    }

    @Test func singersAndWritersAreTheSamePeople() throws {
        let garcia = try #require(Fixtures.song("ripple").singer)
        #expect(catalog.singers.map(\.id) == ["jerry-garcia", "phil-lesh", "pigpen"])
        #expect(catalog.songs(sungBy: garcia).map(\.id) == ["friend-of-the-devil", "morning-dew", "ripple", "sugaree"])
        #expect(catalog.songs(creditedTo: garcia).map(\.id) == ["friend-of-the-devil", "ripple", "sugaree"])
        #expect(Fixtures.song("ripple").credits.first { $0.role == .music }?.person.imageFileName == "jerry-garcia.jpg")
    }

    @Test func fixtureHasNoProblems() {
        #expect(catalog.problems.isEmpty)
    }

    @Test func unknownReferencesAreReportedButTheSongStillLoads() throws {
        let seeds = """
        {
          "artists": [{ "name": "Grateful Dead", "albums": [{ "name": "Go to Heaven", "slug": "go-to-heaven", "songs": [
            { "name": "Althea", "slug": "althea", "fileName": "Althea Score.pdf", "singer": "keith-godchaux",
              "writers": [["robert-hunter", "lyrics"], ["mystery", "music"], ["robert-hunter"]] },
            { "name": "Althea", "slug": "althea", "fileName": "Althea Score.pdf" }
          ]}]}],
          "singers": [],
          "writers": [
            { "name": "Robert Hunter", "slug": "robert-hunter", "contribution": "lyrics" },
            { "name": "Jerry Garcia", "slug": "jerry-garcia", "contribution": "arrangement" }
          ]
        }
        """
        let catalog = try Catalog(seedData: Data(seeds.utf8))
        let althea = try #require(catalog.song(id: "althea"))

        #expect(althea.singer == nil)
        #expect(althea.credits.map(\.person.id) == ["robert-hunter"])
        #expect(althea.lyrics == "")
        #expect(catalog.songs.count == 1)
        #expect(catalog.problems == [
            "Writer jerry-garcia has unknown contribution \"arrangement\"",
            "Song althea has unknown singer keith-godchaux",
            "Song althea has unknown writer [\"mystery\", \"music\"]",
            "Song althea has unknown writer [\"robert-hunter\"]",
            "Song althea appears more than once",
        ])
    }
}
