#if os(iOS) || os(macOS)
import CloudKit
import DeadSheetsKit
import Foundation
import Observation
import os
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Shares the selected song between devices on the same iCloud account through a single CloudKit record.
///
/// Nothing touches CloudKit until sync is turned on. While the app is active it polls the record,
/// because CloudKit's silent pushes arrive too late to follow along; in the background it relies on
/// a query subscription.
@Observable
final class CloudSyncManager {
    static let shared = CloudSyncManager()

    /// The song most recently selected on another device.
    private(set) var selectedSongSlug: String?

    var isEnabled: Bool = UserDefaults.standard.bool(forKey: DefaultsKey.enabled) {
        didSet {
            guard isEnabled != oldValue else { return }
            UserDefaults.standard.set(isEnabled, forKey: DefaultsKey.enabled)
            if isEnabled {
                Task { await saveSubscription() }
            } else {
                Task { await deleteSubscription() }
            }
            updatePolling()
        }
    }

    @ObservationIgnored private var isAppActive = false
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    private static let pollInterval: Duration = .seconds(3)
    private static let errorBackoff: Duration = .seconds(30)
    private static let recordType = "SongSelection"
    private static let subscriptionID = "song-selection-changes"
    private static let recordID = CKRecord.ID(recordName: "currentSelection")

    private enum DefaultsKey {
        static let enabled = "syncWithOtherDevices"
        static let deviceID = "syncDeviceID"
    }

    private enum Field {
        static let slug = "slug"
        static let sender = "sender"
        static let timestamp = "timestamp"
    }

    /// Identifies this install, so a device ignores its own selection but still follows another device of
    /// the same kind.
    private let deviceID: String = {
        if let id = UserDefaults.standard.string(forKey: DefaultsKey.deviceID) {
            return id
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: DefaultsKey.deviceID)
        return id
    }()

    private var database: CKDatabase {
        CKContainer.default().privateCloudDatabase
    }

    private init() {
        #if os(iOS)
        let didBecomeActive = UIApplication.didBecomeActiveNotification
        let willResignActive = UIApplication.willResignActiveNotification
        #elseif os(macOS)
        let didBecomeActive = NSApplication.didBecomeActiveNotification
        let willResignActive = NSApplication.willResignActiveNotification
        #endif
        let center = NotificationCenter.default
        center.addObserver(forName: didBecomeActive, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                CloudSyncManager.shared.isAppActive = true
                CloudSyncManager.shared.updatePolling()
            }
        }
        center.addObserver(forName: willResignActive, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                CloudSyncManager.shared.isAppActive = false
                CloudSyncManager.shared.updatePolling()
            }
        }

        if isEnabled {
            Task { await saveSubscription() }
        }
    }

    func isAccountAvailable() async -> Bool {
        do {
            return try await CKContainer.default().accountStatus() == .available
        } catch {
            Logger.sync.error("Couldn't check the iCloud account: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func sendSelection(slug: String) {
        guard isEnabled else { return }
        Task {
            do {
                let record = try await existingRecord() ?? CKRecord(recordType: Self.recordType, recordID: Self.recordID)
                record[Field.slug] = slug
                record[Field.sender] = deviceID
                record[Field.timestamp] = Date()
                try await database.save(record)
            } catch {
                Logger.sync.error("Couldn't save the selection: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Called by the app delegate for CloudKit's silent pushes.
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) async {
        guard isEnabled,
              let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
              notification.subscriptionID == Self.subscriptionID
        else { return }
        await fetchSelection()
    }

    // MARK: - Polling

    private func updatePolling() {
        if isEnabled && isAppActive {
            guard pollTask == nil else { return }
            pollTask = Task {
                while !Task.isCancelled {
                    let delay = await fetchSelection()
                    try? await Task.sleep(for: delay)
                }
            }
        } else {
            pollTask?.cancel()
            pollTask = nil
        }
    }

    /// Returns how long to wait before fetching again.
    @discardableResult
    private func fetchSelection() async -> Duration {
        do {
            guard let record = try await existingRecord() else { return Self.pollInterval }
            apply(record)
            return Self.pollInterval
        } catch let error as CKError {
            if let retryAfter = error.retryAfterSeconds {
                return .seconds(retryAfter)
            }
            Logger.sync.error("Couldn't fetch the selection: \(error.localizedDescription, privacy: .public)")
            return Self.errorBackoff
        } catch {
            Logger.sync.error("Couldn't fetch the selection: \(error.localizedDescription, privacy: .public)")
            return Self.errorBackoff
        }
    }

    private func apply(_ record: CKRecord) {
        guard let slug = record[Field.slug] as? String, !slug.isEmpty,
              record[Field.sender] as? String != deviceID,
              slug != selectedSongSlug
        else { return }
        selectedSongSlug = slug
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            WatchConnectivityManager.shared.sendSelectedSong(id: slug)
        }
        #endif
    }

    private func existingRecord() async throws -> CKRecord? {
        do {
            return try await database.record(for: Self.recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    // MARK: - Subscription

    private func saveSubscription() async {
        do {
            let subscriptions = try await database.allSubscriptions()
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
            try await database.save(subscription)
        } catch {
            Logger.sync.error("Couldn't save the subscription: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func deleteSubscription() async {
        do {
            try await database.deleteSubscription(withID: Self.subscriptionID)
        } catch let error as CKError where error.code == .unknownItem {
        } catch {
            Logger.sync.error("Couldn't delete the subscription: \(error.localizedDescription, privacy: .public)")
        }
    }
}
#endif
