#if os(iOS) || os(macOS)
import CloudKit
import DeadSheetsKit
import Foundation

struct CloudSongSelection: Sendable {
    let selection: SongSelection
    let sender: String
}

@MainActor
protocol CloudSelectionStore {
    func fetch() async throws -> CloudSongSelection?
    func save(_ selection: CloudSongSelection) async throws
    func setSubscription(enabled: Bool) async throws
}

struct CloudKitSelectionStore: CloudSelectionStore {
    static let subscriptionID = "song-selection-changes"
    private static let recordType = "SongSelection"
    private static let recordID = CKRecord.ID(recordName: "currentSelection")

    var readRecord: () async throws -> CKRecord = {
        try await CKContainer.default().privateCloudDatabase.record(for: recordID)
    }
    var writeRecord: (CKRecord) async throws -> CKRecord = {
        try await CKContainer.default().privateCloudDatabase.save($0)
    }

    func fetch() async throws -> CloudSongSelection? {
        guard let record = try await existingRecord(),
            let songID = record["slug"] as? String, !songID.isEmpty,
            let sender = record["sender"] as? String, !sender.isEmpty,
            let date = record["timestamp"] as? Date, date.timeIntervalSince1970.isFinite
        else { return nil }
        return CloudSongSelection(selection: SongSelection(songID: songID, date: date), sender: sender)
    }

    func save(_ value: CloudSongSelection) async throws {
        var record = try await existingRecord() ?? CKRecord(recordType: Self.recordType, recordID: Self.recordID)
        for attempt in 0..<3 {
            try Task.checkCancellation()
            if let date = record["timestamp"] as? Date, date >= value.selection.date {
                return
            }
            record["slug"] = value.selection.songID
            record["sender"] = value.sender
            record["timestamp"] = value.selection.date
            do {
                _ = try await writeRecord(record)
                return
            } catch let error as CKError where error.code == .serverRecordChanged && attempt < 2 {
                guard let serverRecord = error.serverRecord else { throw error }
                record = serverRecord
            }
        }
    }

    private func existingRecord() async throws -> CKRecord? {
        do {
            return try await readRecord()
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func setSubscription(enabled: Bool) async throws {
        try Task.checkCancellation()
        let database = CKContainer.default().privateCloudDatabase
        if enabled {
            let subscriptions = try await database.allSubscriptions()
            try Task.checkCancellation()
            guard !subscriptions.contains(where: { $0.subscriptionID == Self.subscriptionID }) else { return }
            let subscription = CKQuerySubscription(
                recordType: Self.recordType,
                predicate: NSPredicate(value: true),
                subscriptionID: Self.subscriptionID,
                options: [.firesOnRecordCreation, .firesOnRecordUpdate]
            )
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            _ = try await database.save(subscription)
        } else {
            do {
                try await database.deleteSubscription(withID: Self.subscriptionID)
            } catch let error as CKError where error.code == .unknownItem {
            }
        }
    }
}
#endif
