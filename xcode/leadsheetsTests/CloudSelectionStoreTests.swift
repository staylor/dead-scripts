#if os(iOS) || os(macOS)
import CloudKit
import DeadSheetsKit
import Foundation
import Testing

@testable import Dead_Sheets

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct CloudSelectionStoreTests {
    @Test func missingRecordsAreAnEmptySelection() async throws {
        let store = CloudKitSelectionStore(readRecord: { throw CKError(.unknownItem) })
        #expect(try await store.fetch() == nil)
    }

    @Test func malformedRecordsAreIgnored() async throws {
        let record = CKRecord(recordType: "SongSelection")
        let store = CloudKitSelectionStore(readRecord: { record })
        #expect(try await store.fetch() == nil)
    }

    @Test func conflictsRetryAgainstTheServerRecord() async throws {
        let initial = record(at: 10)
        let server = record(at: 15)
        var attempts = 0
        let store = CloudKitSelectionStore(
            readRecord: { initial },
            writeRecord: { record in
                attempts += 1
                if attempts == 1 {
                    throw CKError(.serverRecordChanged, userInfo: [CKRecordChangedErrorServerRecordKey: server])
                }
                #expect(record === server)
                return record
            }
        )
        try await store.save(selection(at: 20))
        #expect(attempts == 2)
        #expect(server["slug"] as? String == "ripple")
        #expect(server["timestamp"] as? Date == Date(timeIntervalSince1970: 20))
    }

    @Test func aConflictWithANewerSelectionDoesNotOverwriteIt() async throws {
        let initial = record(at: 10)
        let server = record(at: 30)
        var attempts = 0
        let store = CloudKitSelectionStore(
            readRecord: { initial },
            writeRecord: { _ in
                attempts += 1
                throw CKError(.serverRecordChanged, userInfo: [CKRecordChangedErrorServerRecordKey: server])
            }
        )
        try await store.save(selection(at: 20))
        #expect(attempts == 1)
        #expect(server["slug"] as? String == "althea")
    }

    @Test func persistentConflictsAreNotRetriedInATightLoop() async throws {
        var attempts = 0
        let store = CloudKitSelectionStore(
            readRecord: { record(at: 10) },
            writeRecord: { _ in
                attempts += 1
                throw CKError(.serverRecordChanged, userInfo: [CKRecordChangedErrorServerRecordKey: record(at: 15)])
            }
        )
        await #expect(throws: CKError.self) {
            try await store.save(selection(at: 20))
        }
        #expect(attempts == 3)
    }

    @Test func cancellationWhileReadingPreventsTheWrite() async throws {
        let response = TestSuspension<CKRecord>()
        var writes = 0
        let store = CloudKitSelectionStore(
            readRecord: response.value,
            writeRecord: { record in
                writes += 1
                return record
            }
        )
        let saving = Task { try await store.save(selection(at: 20)) }
        await response.started.wait()
        saving.cancel()
        response.resume(returning: record(at: 10))
        await #expect(throws: CancellationError.self) {
            try await saving.value
        }
        #expect(writes == 0)
    }

    private func record(at timestamp: TimeInterval) -> CKRecord {
        let record = CKRecord(recordType: "SongSelection", recordID: CKRecord.ID(recordName: "currentSelection"))
        record["slug"] = "althea"
        record["sender"] = "other-device"
        record["timestamp"] = Date(timeIntervalSince1970: timestamp)
        return record
    }

    private func selection(at timestamp: TimeInterval) -> CloudSongSelection {
        CloudSongSelection(
            selection: SongSelection(songID: "ripple", date: Date(timeIntervalSince1970: timestamp)),
            sender: "this-device"
        )
    }
}
#endif
