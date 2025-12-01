import Foundation
import CloudKit
import Combine
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

    private let container = CKContainer.default()
    private let recordType = "SongSelection"
    private let recordID = CKRecord.ID(recordName: "currentSelection")
    private var cancellables = Set<AnyCancellable>()

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

        // Fetch when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.fetchCurrentSelection()
            }
            .store(in: &cancellables)
        #elseif os(macOS)
        // Fetch when app becomes active
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.fetchCurrentSelection()
            }
            .store(in: &cancellables)
        #endif

        // Poll every 5 seconds to receive updates from other devices
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchCurrentSelection()
            }
            .store(in: &cancellables)

        initializeSchema()
    }

    private func initializeSchema() {
        container.privateCloudDatabase.fetch(withRecordID: recordID) { [weak self] record, _ in
            if record == nil {
                let record = CKRecord(recordType: self?.recordType ?? "SongSelection", recordID: self?.recordID ?? CKRecord.ID(recordName: "currentSelection"))
                record["slug"] = ""
                record["timestamp"] = Date()
                self?.container.privateCloudDatabase.save(record) { _, _ in }
            }
        }
    }

    func sendSelection(slug: String) {
        container.privateCloudDatabase.fetch(withRecordID: recordID) { [weak self] existingRecord, _ in
            guard let self = self else { return }

            let record = existingRecord ?? CKRecord(recordType: self.recordType, recordID: self.recordID)
            record["slug"] = slug
            record["sender"] = self.currentIdiom
            record["timestamp"] = Date()

            self.container.privateCloudDatabase.save(record) { _, error in
                if let error = error {
                    print("CloudKit save error: \(error.localizedDescription)")
                }
            }
        }
    }

    func fetchCurrentSelection() {
        container.privateCloudDatabase.fetch(withRecordID: recordID) { [weak self] record, _ in
            guard let self = self,
                  let record = record,
                  let slug = record["slug"] as? String,
                  !slug.isEmpty else {
                print("CloudKit: no valid record")
                return
            }

            let sender = record["sender"] as? String ?? "unknown"
            print("CloudKit: fetched slug=\(slug), sender=\(sender), currentIdiom=\(self.currentIdiom)")

            guard sender != self.currentIdiom else {
                print("CloudKit: ignoring own record")
                return
            }

            DispatchQueue.main.async {
                print("CloudKit: updating selectedSongSlug to \(slug)")
                self.senderIdiom = sender
                self.selectedSongSlug = slug
            }
        }
    }
}
#endif
