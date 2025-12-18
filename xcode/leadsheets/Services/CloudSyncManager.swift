import Foundation
import CloudKit
import Combine
import SwiftUI
#if os(iOS)
import UIKit
import WatchConnectivity
#elseif os(macOS)
import AppKit
#endif

#if os(iOS) || os(macOS)
class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    @Published var selectedSongSlug: String?
    @Published var senderIdiom: String?
    @AppStorage("syncWithOtherDevices") private var syncEnabled = false

    private let container = CKContainer.default()
    private let recordType = "SongSelection"
    private let subscriptionID = "song-selection-changes"
    private let recordID = CKRecord.ID(recordName: "currentSelection")
    private var cancellables = Set<AnyCancellable>()
    private var pollingTimer: AnyCancellable?

    private var currentIdiom: String {
        #if os(macOS)
        return "mac"
        #else
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: return "phone"
        case .pad: return "pad"
        default: return "unknown"
        }
        #endif
    }

    private init() {
        #if os(iOS)
        // Forward CloudKit changes to Watch (iPhone only)
        if UIDevice.current.userInterfaceIdiom == .phone {
            $selectedSongSlug
                .compactMap { $0 }
                .removeDuplicates()
                .sink { slug in
                    WatchConnectivityManager.shared.sendSelectedSong(songID: slug, songName: "")
                }
                .store(in: &cancellables)
        }
        #endif

        // Observe sync setting changes
        UserDefaults.standard.publisher(for: \.syncWithOtherDevices)
            .sink { [weak self] enabled in
                self?.updateSyncState(enabled: enabled)
            }
            .store(in: &cancellables)

        // Listen for app lifecycle to start/stop polling
        #if os(iOS)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.startPollingIfEnabled()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.stopPolling()
            }
            .store(in: &cancellables)
        #elseif os(macOS)
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.startPollingIfEnabled()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.stopPolling()
            }
            .store(in: &cancellables)
        #endif

        // Setup subscription for background notifications + start polling for foreground
        if syncEnabled {
            setupSubscription()
            startPolling()
            fetchCurrentSelection()
        }

        initializeSchema()
    }

    private func updateSyncState(enabled: Bool) {
        if enabled {
            setupSubscription()
            startPolling()
            fetchCurrentSelection()
        } else {
            removeSubscription()
            stopPolling()
        }
    }

    private func startPollingIfEnabled() {
        if syncEnabled {
            startPolling()
            fetchCurrentSelection()
        }
    }

    private func startPolling() {
        guard pollingTimer == nil else { return }
        pollingTimer = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchCurrentSelection()
            }
    }

    private func stopPolling() {
        pollingTimer?.cancel()
        pollingTimer = nil
    }

    // MARK: - CloudKit Subscription

    private func setupSubscription() {
        Task {
            do {
                // Check if subscription already exists
                let existingSubscriptions = try await container.privateCloudDatabase.allSubscriptions()
                if existingSubscriptions.contains(where: { $0.subscriptionID == subscriptionID }) {
                    print("CloudKit: Subscription already exists")
                    return
                }

                // Create a query subscription that triggers on any change to SongSelection records
                let predicate = NSPredicate(value: true)
                let subscription = CKQuerySubscription(
                    recordType: recordType,
                    predicate: predicate,
                    subscriptionID: subscriptionID,
                    options: [.firesOnRecordCreation, .firesOnRecordUpdate]
                )

                let notificationInfo = CKSubscription.NotificationInfo()
                notificationInfo.shouldSendContentAvailable = true
                subscription.notificationInfo = notificationInfo

                try await container.privateCloudDatabase.save(subscription)
                print("CloudKit: Subscription created successfully")
            } catch {
                print("CloudKit subscription error: \(error.localizedDescription)")
            }
        }
    }

    private func removeSubscription() {
        Task {
            do {
                try await container.privateCloudDatabase.deleteSubscription(withID: subscriptionID)
                print("CloudKit: Subscription removed")
            } catch {
                // Subscription may not exist - ignore
            }
        }
    }

    /// Call this from AppDelegate when receiving a remote notification
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        print("CloudKit: Received remote notification")

        guard syncEnabled else {
            print("CloudKit: Sync disabled, ignoring notification")
            return
        }

        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            print("CloudKit: Notification subscription ID: \(notification.subscriptionID ?? "nil")")
            guard notification.subscriptionID == subscriptionID else {
                print("CloudKit: Subscription ID mismatch, ignoring")
                return
            }
        }

        print("CloudKit: Fetching current selection...")
        fetchCurrentSelection()
    }

    private func initializeSchema() {
        Task {
            do {
                _ = try await container.privateCloudDatabase.record(for: recordID)
            } catch {
                // Record doesn't exist, create it
                let record = CKRecord(recordType: recordType, recordID: recordID)
                record["slug"] = ""
                record["timestamp"] = Date()
                _ = try? await container.privateCloudDatabase.save(record)
            }
        }
    }

    func sendSelection(slug: String) {
        guard syncEnabled else { return }

        Task {
            do {
                let existingRecord = try? await container.privateCloudDatabase.record(for: recordID)
                let record = existingRecord ?? CKRecord(recordType: recordType, recordID: recordID)
                record["slug"] = slug
                record["sender"] = currentIdiom
                record["timestamp"] = Date()
                try await container.privateCloudDatabase.save(record)
            } catch {
                print("CloudKit save error: \(error.localizedDescription)")
            }
        }
    }

    func fetchCurrentSelection() {
        guard syncEnabled else { return }

        Task {
            do {
                let record = try await container.privateCloudDatabase.record(for: recordID)
                guard let slug = record["slug"] as? String, !slug.isEmpty else { return }

                let sender = record["sender"] as? String ?? "unknown"
                guard sender != currentIdiom else { return }

                await MainActor.run {
                    senderIdiom = sender
                    selectedSongSlug = slug
                }
            } catch {
                // Record not found or network error - ignore silently
            }
        }
    }
}

// MARK: - UserDefaults KVO Extension
extension UserDefaults {
    @objc dynamic var syncWithOtherDevices: Bool {
        bool(forKey: "syncWithOtherDevices")
    }
}
#endif
