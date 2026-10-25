import Testing
@testable import DeadSheetsKit

struct SearchTests {
    let catalog = Fixtures.catalog

    @Test func emptyQueryReturnsEverything() {
        #expect(catalog.songs(matching: "").count == catalog.songs.count)
        #expect(catalog.albums(matching: "").count == catalog.albums.count)
    }

    @Test func matchesTitleArtistAlbumAndLyricsIgnoringCaseAndAccents() {
        #expect(catalog.songs(matching: "rípple").map(\.id) == ["ripple"])
        #expect(catalog.songs(matching: "reno").map(\.id) == ["friend-of-the-devil"])
        #expect(catalog.songs(matching: "american beauty").map(\.id) == ["box-of-rain", "friend-of-the-devil", "ripple"])
        #expect(catalog.songs(matching: "JERRY GARCIA").map(\.id) == ["sugaree"])
    }

    @Test func coversMatchTheirSinger() {
        #expect(catalog.covers(matching: "").map(\.id) == ["big-boss-man", "morning-dew"])
        #expect(catalog.covers(matching: "pigpen").map(\.id) == ["big-boss-man"])
    }

    @Test func albumsMatchTheirArtist() {
        #expect(catalog.albums(matching: "jerry").map(\.id) == ["garcia"])
    }

    @Test func singersAndArtistsMatchByName() {
        #expect(catalog.singers(matching: "lesh").map(\.id) == ["phil-lesh"])
        #expect(catalog.artists(matching: "dead").map(\.id) == ["grateful-dead"])
    }
}

struct LyricsTests {
    @Test func splitsParagraphsOnBlankLines() {
        let song = Fixtures.song("ripple")
        #expect(song.lyricParagraphs == [["If my words did glow"], ["Chorus:", "Ripple in still water"]])
        #expect(song.lyricLines == ["If my words did glow", "", "Chorus:", "Ripple in still water"])
    }

    @Test func recognizesChorusHeadings() {
        #expect(Song.isChorusHeading("Chorus:"))
        #expect(!Song.isChorusHeading("If my words did glow"))
    }
}
