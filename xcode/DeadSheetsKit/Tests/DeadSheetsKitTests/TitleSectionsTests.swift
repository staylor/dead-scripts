import Foundation
import Testing

@testable import DeadSheetsKit

struct TitleSectionsTests {
    @Test func accentedAndLowercaseTitlesFileUnderTheirBaseLetterInCatalogOrder() throws {
        let catalog = try makeCatalog(titles: ["Zebra", "Éxtasis", "eagle", "Echo", "1999"])
        let sections = catalog.songs.titleSections()
        #expect(sections.map(\.heading) == ["#", "E", "Z"])
        #expect(sections.flatMap(\.songs) == catalog.songs)
        #expect(sections[1].songs.map(\.title) == ["eagle", "Echo", "Éxtasis"])
    }

    @Test func titlesWithoutALeadingLetterShareOneSection() throws {
        let catalog = try makeCatalog(titles: ["Apple", "(Intro)", "1999"])
        let sections = catalog.songs.titleSections()
        #expect(sections.map(\.heading) == ["#", "A"])
        #expect(Set(sections[0].songs.map(\.title)) == ["(Intro)", "1999"])
    }

    @Test func emptyListsHaveNoSections() {
        #expect([Song]().titleSections().isEmpty)
    }

    private func makeCatalog(titles: [String]) throws -> Catalog {
        let songs = titles.enumerated().map { index, title in
            ["name": title, "slug": "song-\(index)", "fileName": "\(index).pdf"]
        }
        let artist: [String: Any] = [
            "name": "Artist", "slug": "artist", "albums": [["name": "Album", "slug": "album", "songs": songs]],
        ]
        let seeds: [String: Any] = ["artists": [artist], "singers": [], "writers": []]
        return try Catalog(seedData: JSONSerialization.data(withJSONObject: seeds))
    }
}
