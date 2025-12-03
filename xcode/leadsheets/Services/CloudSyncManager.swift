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
    private let recordID = CKRecord.ID(recordName: "currentSelection")
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?

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
                self?.updateTimerState(enabled: enabled)
            }
            .store(in: &cancellables)

        // Start timer if sync is already enabled
        if syncEnabled {
            startPollingTimer()
        }

        initializeSchema()
    }

    private func updateTimerState(enabled: Bool) {
        if enabled {
            startPollingTimer()
            fetchCurrentSelection()
        } else {
            stopPollingTimer()
        }
    }

    private func startPollingTimer() {
        guard timerCancellable == nil else { return }
        timerCancellable = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchCurrentSelection()
            }
    }

    private func stopPollingTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
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
                try? await container.privateCloudDatabase.save(record)
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
