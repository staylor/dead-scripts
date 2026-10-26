import Testing

@testable import DeadSheetsKit

struct CreditsTests {
    @Test func listsEachRoleAlphabetically() {
        #expect(Fixtures.song("friend-of-the-devil").creditsText == "Lyrics: Robert Hunter, Music: Jerry Garcia & John Dawson")
    }

    @Test func combinesRolesWrittenByTheSamePeople() {
        #expect(Fixtures.song("morning-dew").creditsText == "Music & Lyrics: Bonnie Dobson")
    }

    @Test func showsAPlaceholderWithoutCredits() throws {
        let seeds = """
            { "artists": [{ "name": "Grateful Dead", "albums": [{ "name": "Dead Set", "slug": "dead-set", "songs": [
                { "name": "Space", "slug": "space", "fileName": "Space Score.pdf" }
            ]}]}], "singers": [], "writers": [] }
            """
        let catalog = try Catalog(seedData: .init(seeds.utf8))
        #expect(catalog.song(id: "space")?.creditsText == "Unknown Writer")
    }

    @Test(arguments: [
        ([], ""),
        (["Jerry Garcia"], "Jerry Garcia"),
        (["Jerry Garcia", "Robert Hunter"], "Jerry Garcia & Robert Hunter"),
        (["Bill Kreutzmann", "Jerry Garcia", "Phil Lesh"], "Bill Kreutzmann, Jerry Garcia & Phil Lesh"),
    ])
    func joinsNames(names: [String], expected: String) {
        #expect(Song.list(names) == expected)
    }
}
