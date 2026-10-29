#if os(iOS) || os(macOS)
import Foundation
import SwiftData
import Testing

@testable import Dead_Sheets

@MainActor
struct UserDataTests {
    @Test func inMemoryStoresAreWritableAndDoNotUseCloudKit() throws {
        let data = try UserData(isStoredInMemoryOnly: true)
        #expect(data.isAvailable)
        #expect(!data.container.mainContext.autosaveEnabled)
        let configuration = try #require(data.container.configurations.first)
        #expect(configuration.isStoredInMemoryOnly)
        #expect(configuration.cloudKitContainerIdentifier == nil)
    }

    @Test func favoritesAndSetlistsSurviveReopeningTheStore() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "UserData.store")
        let data = try UserData(url: url)
        let context = data.container.mainContext
        #expect(data.isAvailable)
        #expect(data.container.configurations.first?.cloudKitContainerIdentifier == nil)
        #expect(
            data.save(in: context) {
                context.insert(Favorite(songID: "ripple"))
                context.insert(Setlist(name: "Saturday", songIDs: ["ripple", "althea"]))
            } == nil)

        let reopened = try UserData(url: url)
        #expect(reopened.isAvailable)
        #expect(try reopened.container.mainContext.fetch(FetchDescriptor<Favorite>()).map(\.songID) == ["ripple"])
        let setlist = try #require(reopened.container.mainContext.fetch(FetchDescriptor<Setlist>()).first)
        #expect(setlist.name == "Saturday")
        #expect(setlist.songIDs == ["ripple", "althea"])
    }

    @Test func failedInsertsAreRolledBack() throws {
        let data = try UserData(isStoredInMemoryOnly: true)
        let context = data.container.mainContext
        let failure = data.save(in: context, using: failSave) {
            context.insert(Favorite(songID: "ripple"))
            context.insert(Setlist(name: "Saturday"))
        }
        #expect(failure != nil)
        #expect(!context.hasChanges)
        #expect(try context.fetchCount(FetchDescriptor<Favorite>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Setlist>()) == 0)
    }

    @Test func failedEditsAndDeletesRestoreSavedData() throws {
        let data = try UserData(isStoredInMemoryOnly: true)
        let context = data.container.mainContext
        let favorite = Favorite(songID: "ripple")
        let setlist = Setlist(name: "Saturday", songIDs: ["ripple", "althea"])
        #expect(
            data.save(in: context) {
                context.insert(favorite)
                context.insert(setlist)
            } == nil)

        let failure = data.save(in: context, restoring: [setlist], using: failSave) {
            context.delete(favorite)
            setlist.songIDs = ["althea", "ripple"]
        }
        #expect(failure != nil)
        #expect(!context.hasChanges)
        #expect(try context.fetchCount(FetchDescriptor<Favorite>()) == 1)
        #expect(setlist.songIDs == ["ripple", "althea"])
    }

    @Test func failedOpenFallsBackWithoutAllowingUnsavedChanges() throws {
        var attempts: [ModelConfiguration] = []
        let data = try UserData { configuration in
            attempts.append(configuration)
            if !configuration.isStoredInMemoryOnly {
                throw CocoaError(.fileReadCorruptFile)
            }
            return try ModelContainer(for: UserData.schema, configurations: configuration)
        }
        #expect(attempts.count == 2)
        #expect(!attempts[0].isStoredInMemoryOnly)
        #expect(attempts[1].isStoredInMemoryOnly)
        #expect(attempts.allSatisfy { $0.cloudKitContainerIdentifier == nil })
        #expect(!data.isAvailable)
        var changed = false
        #expect(data.save(in: data.container.mainContext) { changed = true } != nil)
        #expect(!changed)
    }

    @Test func failedFallbackPropagatesTheError() {
        #expect(throws: CocoaError.self) {
            try UserData { _ in throw CocoaError(.fileReadCorruptFile) }
        }
    }

    private func failSave(_: ModelContext) throws {
        throw CocoaError(.fileWriteOutOfSpace)
    }
}
#endif
