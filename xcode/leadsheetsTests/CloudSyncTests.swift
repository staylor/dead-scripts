#if os(iOS) || os(macOS)
import CloudKit
import DeadSheetsKit
import Foundation
import Testing

@testable import Dead_Sheets

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct CloudSyncTests {
    @Test func disabledSyncDoesNotReadWriteOrSubscribe() async throws {
        let fixture = try CloudSyncFixture()
        defer { fixture.cleanUp() }
        await fixture.manager.fetchSelection()
        fixture.manager.sendSelectedSong(id: "ripple")
        #expect(fixture.store.fetchCount == 0)
        #expect(fixture.store.saves.isEmpty)
        #expect(fixture.store.subscriptions.isEmpty)
    }

    @Test func aFetchFromAnEarlierEnabledSessionCannotChangeTheSelection() async throws {
        let fixture = try CloudSyncFixture()
        defer { fixture.cleanUp() }
        let response = TestSuspension<CloudSongSelection?>()
        fixture.store.onFetch = response.value
        fixture.manager.isEnabled = true
        let fetch = Task { await fixture.manager.fetchSelection() }
        await response.started.wait()
        fixture.manager.isEnabled = false
        fixture.manager.isEnabled = true
        response.resume(returning: remote("ripple", at: 10))
        _ = await fetch.value
        #expect(fixture.manager.selection == nil)
    }

    @Test func simultaneousPollsAndPushesShareOneFetch() async throws {
        let fixture = try CloudSyncFixture()
        defer { fixture.cleanUp() }
        let response = TestSuspension<CloudSongSelection?>()
        fixture.store.onFetch = {
            fixture.store.fetchCount == 1 ? try await response.value() : nil
        }
        fixture.manager.isEnabled = true
        let first = Task { await fixture.manager.fetchSelection() }
        await response.started.wait()
        let entered = TestSignal()
        let second = Task {
            entered.signal()
            return await fixture.manager.fetchSelection()
        }
        await entered.wait()
        #expect(fixture.store.fetchCount == 1)
        response.resume(returning: remote("ripple", at: 10))
        _ = await first.value
        _ = await second.value
        #expect(fixture.store.fetchCount == 1)
        #expect(fixture.manager.selection?.songID == "ripple")
    }

    @Test func oldAndDuplicateRecordsAreIgnoredButReselectingASongIsForwarded() async throws {
        var received: [SongSelection] = []
        let fixture = try CloudSyncFixture { received.append($0) }
        defer { fixture.cleanUp() }
        fixture.manager.isEnabled = true
        for value in [remote("ripple", at: 20), remote("althea", at: 10), remote("ripple", at: 20), remote("ripple", at: 30)] {
            fixture.store.current = value
            await fixture.manager.fetchSelection()
        }
        #expect(received.map(\.songID) == ["ripple", "ripple"])
        #expect(fixture.manager.selection?.date == date(30))
    }

    @Test func lateFetchesCannotReplaceALocalChoice() async throws {
        let fixture = try CloudSyncFixture()
        defer { fixture.cleanUp() }
        let response = TestSuspension<CloudSongSelection?>()
        fixture.store.onFetch = response.value
        fixture.manager.isEnabled = true
        let fetch = Task { await fixture.manager.fetchSelection() }
        await response.started.wait()
        fixture.manager.sendSelectedSong(id: "ripple")
        await fixture.manager.sendTask?.value
        response.resume(returning: remote("althea", at: 10))
        _ = await fetch.value
        #expect(fixture.manager.selection == nil)
        #expect(fixture.store.saves.map(\.selection.songID) == ["ripple"])
    }

    @Test func writesAreSerializedAndIntermediateChoicesAreCoalesced() async throws {
        let fixture = try CloudSyncFixture()
        defer { fixture.cleanUp() }
        let response = TestSuspension<Void>()
        fixture.store.onSave = { _ in
            if fixture.store.saves.count == 1 {
                try await response.value()
            }
        }
        fixture.manager.isEnabled = true
        fixture.manager.sendSelectedSong(id: "ripple")
        await response.started.wait()
        fixture.manager.sendSelectedSong(id: "althea")
        fixture.manager.sendSelectedSong(id: "box-of-rain")
        #expect(fixture.store.saves.count == 1)
        response.resume(returning: ())
        await fixture.manager.sendTask?.value
        #expect(fixture.store.saves.map(\.selection.songID) == ["ripple", "box-of-rain"])
        #expect(fixture.store.saves[0].selection.date < fixture.store.saves[1].selection.date)
    }

    @Test func turningSyncOffDropsQueuedWrites() async throws {
        let fixture = try CloudSyncFixture()
        defer { fixture.cleanUp() }
        let response = TestSuspension<Void>()
        fixture.store.onSave = { _ in
            if fixture.store.saves.count == 1 {
                try await response.value()
            }
        }
        fixture.manager.isEnabled = true
        fixture.manager.sendSelectedSong(id: "ripple")
        await response.started.wait()
        let sending = fixture.manager.sendTask
        fixture.manager.sendSelectedSong(id: "althea")
        fixture.manager.isEnabled = false
        response.resume(returning: ())
        await sending?.value
        #expect(fixture.store.saves.map(\.selection.songID) == ["ripple"])
    }

    @Test func disablingWaitsForAnInFlightSubscriptionBeforeDeletingIt() async throws {
        let fixture = try CloudSyncFixture()
        defer { fixture.cleanUp() }
        let response = TestSuspension<Void>()
        fixture.store.onSubscription = { enabled in
            if enabled {
                try await response.value()
            }
        }
        fixture.manager.isEnabled = true
        await response.started.wait()
        fixture.manager.isEnabled = false
        response.resume(returning: ())
        await fixture.manager.subscriptionTask?.value
        #expect(fixture.store.subscriptions == [true, false])
        #expect(!fixture.store.subscriptionEnabled)
    }

    @Test func forwardsWatchSelectionsWithTheirOriginalDates() async throws {
        let fixture = try CloudSyncFixture()
        defer { fixture.cleanUp() }
        fixture.manager.isEnabled = true
        fixture.store.current = remote("ripple", at: 20)
        await fixture.manager.fetchSelection()
        fixture.manager.forwardSelectedSong(remote("althea", at: 10).selection)
        #expect(fixture.manager.sendTask == nil)
        let watch = remote("ripple", at: 30).selection
        fixture.manager.forwardSelectedSong(watch)
        await fixture.manager.sendTask?.value
        #expect(fixture.store.saves.map(\.selection) == [watch])
    }

    @Test func ignoresItsOwnAndUnknownSongs() async throws {
        let fixture = try CloudSyncFixture()
        defer { fixture.cleanUp() }
        fixture.manager.isEnabled = true
        fixture.store.current = CloudSongSelection(selection: remote("ripple", at: 10).selection, sender: "this-device")
        await fixture.manager.fetchSelection()
        fixture.store.current = remote("not-in-the-catalog", at: 20)
        await fixture.manager.fetchSelection()
        #expect(fixture.manager.selection == nil)
    }

    @Test func honorsCloudKitRetryAfter() async throws {
        let fixture = try CloudSyncFixture()
        defer { fixture.cleanUp() }
        fixture.manager.isEnabled = true
        fixture.store.onFetch = {
            throw CKError(.requestRateLimited, userInfo: [CKErrorRetryAfterKey: 120.0])
        }
        #expect(await fixture.manager.fetchSelection() == .seconds(120))
    }

    private func remote(_ songID: String, at timestamp: TimeInterval) -> CloudSongSelection {
        CloudSongSelection(selection: SongSelection(songID: songID, date: date(timestamp)), sender: "other-device")
    }

    private func date(_ timestamp: TimeInterval) -> Date {
        Date(timeIntervalSince1970: timestamp)
    }
}

@MainActor
private struct CloudSyncFixture {
    let domain = "DeadSheetsTests.\(UUID().uuidString)"
    let defaults: UserDefaults
    let store = TestCloudSelectionStore()
    let manager: CloudSyncManager

    init(didReceive: @escaping (SongSelection) -> Void = { _ in }) throws {
        defaults = try #require(UserDefaults(suiteName: domain))
        defaults.set("this-device", forKey: "syncDeviceID")
        manager = CloudSyncManager(store: store, defaults: defaults, now: Self.now, didReceive: didReceive)
    }

    private static func now() -> Date {
        Date(timeIntervalSince1970: 20)
    }

    func cleanUp() {
        manager.isEnabled = false
        store.onFetch = nil
        store.onSave = nil
        store.onSubscription = nil
        defaults.removePersistentDomain(forName: domain)
    }
}

@MainActor
private final class TestCloudSelectionStore: CloudSelectionStore {
    var current: CloudSongSelection?
    var fetchCount = 0
    var saves: [CloudSongSelection] = []
    var subscriptions: [Bool] = []
    var subscriptionEnabled = false
    var onFetch: (() async throws -> CloudSongSelection?)?
    var onSave: ((CloudSongSelection) async throws -> Void)?
    var onSubscription: ((Bool) async throws -> Void)?

    func fetch() async throws -> CloudSongSelection? {
        fetchCount += 1
        if let onFetch {
            return try await onFetch()
        }
        return current
    }

    func save(_ selection: CloudSongSelection) async throws {
        saves.append(selection)
        try await onSave?(selection)
        current = selection
    }

    func setSubscription(enabled: Bool) async throws {
        subscriptions.append(enabled)
        try await onSubscription?(enabled)
        subscriptionEnabled = enabled
    }
}
#endif
