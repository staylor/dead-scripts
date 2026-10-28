import Testing

@testable import DeadSheetsKit

struct WriterGroupsTests {
    let catalog = Fixtures.catalog

    @Test func groupsEveryWriterOnce() {
        let groups = catalog.writerGroups()
        #expect(
            groups.map(\.name) == [
                "Al Smith & Luther Dixon", "Bonnie Dobson", "Jerry Garcia", "John Dawson", "Phil Lesh", "Robert Hunter",
            ])
    }

    @Test func combinesAPersonsRolesOnTheSameSongs() throws {
        let dobson = try #require(catalog.writerGroups().first { $0.name == "Bonnie Dobson" })
        #expect(dobson.rolesText == "Lyrics & Music")
        #expect(dobson.songs.map(\.id) == ["morning-dew"])
        #expect(dobson.appleMusicID == nil)
    }

    @Test func mergesWritersWhoOnlyWroteTogether() throws {
        let group = try #require(catalog.writerGroups().first { $0.people.count > 1 })
        #expect(group.people.map(\.id) == ["al-smith", "luther-dixon"])
        #expect(group.rolesText == "Lyrics & Music")
        #expect(group.songs.map(\.id) == ["big-boss-man"])
    }

    @Test func keepsSoloWritersSeparateFromTheirCollaborators() throws {
        let hunter = try #require(catalog.writerGroups().first { $0.name == "Robert Hunter" })
        #expect(hunter.rolesText == "Lyrics")
        #expect(hunter.songs.map(\.id) == ["box-of-rain", "friend-of-the-devil", "ripple", "sugaree"])
    }

    @Test func usesTheSingersPhotoForWriters() throws {
        let garcia = try #require(catalog.writerGroups().first { $0.name == "Jerry Garcia" })
        #expect(garcia.appleMusicID == "30")
    }

    @Test func filtersByNameOrRoleBeforeGrouping() {
        #expect(catalog.writerGroups(matching: "garcia").map(\.name) == ["Jerry Garcia"])
        #expect(catalog.writerGroups(matching: "lyrics").map(\.name) == ["Bonnie Dobson", "Luther Dixon", "Robert Hunter"])
    }

    @Test func idsAreStableAndUnique() {
        let ids = catalog.writerGroups().map(\.id)
        #expect(ids == catalog.writerGroups().map(\.id))
        #expect(Set(ids).count == ids.count)
        #expect(ids.contains("al-smith+luther-dixon:lyrics+music"))
    }
}
