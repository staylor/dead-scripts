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

@Observable
final class CloudSyncManager {
    static let shared = CloudSyncManager(
        observesAppActivity: true,
        didReceive: { selection in
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone {
                WatchConnectivityManager.shared.forwardSelectedSong(selection)
            }
            #endif
        }
    )

    private(set) var selection: SongSelection?

    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            defaults.set(isEnabled, forKey: DefaultsKey.enabled)
            generation = UUID()
            if !isEnabled {
                sendTask?.cancel()
                sendTask = nil
                fetchRequest?.task.cancel()
                fetchRequest = nil
                state = SongSelectionState()
                selection = nil
            }
            reconcileSubscription()
            updatePolling()
        }
    }

    @ObservationIgnored private(set) var sendTask: Task<Void, Never>?
    @ObservationIgnored private(set) var subscriptionTask: Task<Void, Never>?
    @ObservationIgnored private var fetchRequest: (id: UUID, task: Task<Duration, Never>)?
    @ObservationIgnored private var pollTask: Task<Void, Never>?
    @ObservationIgnored private var isAppActive = false
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var state = SongSelectionState()

    private let store: any CloudSelectionStore
    private let defaults: UserDefaults
    private let deviceID: String
    private let now: () -> Date
    private let didReceive: (SongSelection) -> Void

    private static let pollInterval: Duration = .seconds(3)
    private static let errorBackoff: Duration = .seconds(30)

    private enum DefaultsKey {
        static let enabled = "syncWithOtherDevices"
        static let deviceID = "syncDeviceID"
    }

    init(
        store: any CloudSelectionStore = CloudKitSelectionStore(),
        defaults: UserDefaults = .standard,
        observesAppActivity: Bool = false,
        now: @escaping () -> Date = Date.init,
        didReceive: @escaping (SongSelection) -> Void = { _ in }
    ) {
        self.store = store
        self.defaults = defaults
        self.now = now
        self.didReceive = didReceive
        deviceID = defaults.string(forKey: DefaultsKey.deviceID) ?? UUID().uuidString
        defaults.set(deviceID, forKey: DefaultsKey.deviceID)
        isEnabled = defaults.bool(forKey: DefaultsKey.enabled)
        if observesAppActivity {
            observeAppActivity()
        }
        if isEnabled {
            reconcileSubscription()
        }
    }

    private func observeAppActivity() {
        #if os(iOS)
        let didBecomeActive = UIApplication.didBecomeActiveNotification
        let willResignActive = UIApplication.willResignActiveNotification
        #elseif os(macOS)
        let didBecomeActive = NSApplication.didBecomeActiveNotification
        let willResignActive = NSApplication.willResignActiveNotification
        #endif
        let center = NotificationCenter.default
        center.addObserver(forName: didBecomeActive, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isAppActive = true
                self?.updatePolling()
            }
        }
        center.addObserver(forName: willResignActive, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isAppActive = false
                self?.updatePolling()
            }
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

    func sendSelectedSong(id: Song.ID) {
        guard isEnabled, Catalog.bundled.song(id: id) != nil else { return }
        state.select(songID: id, at: now())
        selection = nil
        sendPendingSelection()
    }

    func forwardSelectedSong(_ selection: SongSelection) {
        guard isEnabled, Catalog.bundled.song(id: selection.songID) != nil, state.forward(selection) else { return }
        self.selection = nil
        sendPendingSelection()
    }

    private func sendPendingSelection() {
        guard sendTask == nil else { return }
        let generation = generation
        sendTask = Task {
            defer {
                if self.generation == generation {
                    sendTask = nil
                }
            }
            while isEnabled, self.generation == generation, !Task.isCancelled, let pending = state.pending {
                do {
                    try await store.save(CloudSongSelection(selection: pending, sender: deviceID))
                    guard self.generation == generation, !Task.isCancelled else { return }
                    state.acknowledge(pending)
                } catch is CancellationError {
                    return
                } catch {
                    Logger.sync.error("Couldn't save the selection: \(error.localizedDescription, privacy: .public)")
                    do {
                        try await Task.sleep(for: Self.retryDelay(for: error))
                    } catch {
                        return
                    }
                }
            }
        }
    }

    func handleRemoteNotification(userInfo: [AnyHashable: Any]) async {
        guard isEnabled,
            let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
            notification.subscriptionID == CloudKitSelectionStore.subscriptionID
        else { return }
        await fetchSelection()
    }

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

    @discardableResult
    func fetchSelection() async -> Duration {
        guard isEnabled else { return Self.pollInterval }
        if let fetchRequest {
            return await fetchRequest.task.value
        }
        let generation = generation
        let id = UUID()
        let task = Task {
            do {
                let value = try await store.fetch()
                guard isEnabled, self.generation == generation, !Task.isCancelled else { return Self.pollInterval }
                if let value {
                    apply(value)
                }
                return Self.pollInterval
            } catch is CancellationError {
                return Self.pollInterval
            } catch {
                Logger.sync.error("Couldn't fetch the selection: \(error.localizedDescription, privacy: .public)")
                return Self.retryDelay(for: error)
            }
        }
        fetchRequest = (id, task)
        let delay = await task.value
        if fetchRequest?.id == id {
            fetchRequest = nil
        }
        return delay
    }

    private func apply(_ value: CloudSongSelection) {
        guard value.sender != deviceID, Catalog.bundled.song(id: value.selection.songID) != nil,
            state.receive(value.selection)
        else { return }
        selection = value.selection
        didReceive(value.selection)
    }

    private func reconcileSubscription() {
        let previous = subscriptionTask
        previous?.cancel()
        let generation = generation
        let enabled = isEnabled
        subscriptionTask = Task {
            await previous?.value
            guard self.generation == generation, !Task.isCancelled else { return }
            do {
                try await store.setSubscription(enabled: enabled)
            } catch is CancellationError {
            } catch {
                Logger.sync.error("Couldn't update the subscription: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private static func retryDelay(for error: any Error) -> Duration {
        if let retryAfter = (error as? CKError)?.retryAfterSeconds, retryAfter.isFinite, retryAfter > 0 {
            return .seconds(retryAfter)
        }
        return errorBackoff
    }
}
#endif
