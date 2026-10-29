#if os(iOS) || os(watchOS)
import Foundation
import Observation
import os
import WatchConnectivity

@MainActor
@Observable
public final class WatchConnectivityManager: NSObject {
    public static let shared = WatchConnectivityManager()

    public private(set) var selection: SongSelection?
    @ObservationIgnored private var state = SongSelectionState()

    override private init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    public func sendSelectedSong(id: Song.ID) {
        guard WCSession.isSupported(), Catalog.bundled.song(id: id) != nil else { return }
        state.select(songID: id, at: Date())
        selection = nil
        flushPendingSelection()
    }

    public func forwardSelectedSong(_ selection: SongSelection) {
        guard WCSession.isSupported(), Catalog.bundled.song(id: selection.songID) != nil, state.forward(selection) else { return }
        self.selection = nil
        flushPendingSelection()
    }

    private func flushPendingSelection() {
        guard WCSession.isSupported(), let pending = state.pending else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        #if os(iOS)
        guard session.isWatchAppInstalled else { return }
        #endif

        let message: [String: Any] = [
            MessageKey.songID: pending.songID,
            MessageKey.timestamp: pending.date.timeIntervalSince1970,
        ]
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                Logger.watchConnectivity.error("sendMessage failed: \(error.localizedDescription)")
            }
        }
        do {
            try session.updateApplicationContext(message)
            state.acknowledge(pending)
        } catch {
            Logger.watchConnectivity.error("updateApplicationContext failed: \(error.localizedDescription)")
        }
    }

    private func receive(_ selection: SongSelection) {
        guard Catalog.bundled.song(id: selection.songID) != nil, state.receive(selection) else { return }
        self.selection = selection
    }

    private nonisolated static func decode(_ message: [String: Any]) -> SongSelection? {
        guard let songID = message[MessageKey.songID] as? String,
            let timestamp = message[MessageKey.timestamp] as? TimeInterval, timestamp.isFinite
        else { return nil }
        return SongSelection(songID: songID, date: Date(timeIntervalSince1970: timestamp))
    }

    private enum MessageKey {
        static let songID = "selectedSongID"
        static let timestamp = "timestamp"
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    public nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        if let error {
            Logger.watchConnectivity.error("Activation failed: \(error.localizedDescription)")
        }
        guard activationState == .activated else { return }
        let sent = Self.decode(session.applicationContext)
        let received = Self.decode(session.receivedApplicationContext)
        Task { @MainActor in
            if let sent, self.state.receive(sent) {
                self.selection = nil
            }
            if let received {
                self.receive(received)
            }
            self.flushPendingSelection()
        }
    }

    #if os(iOS)
    public nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    public nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    public nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.flushPendingSelection()
        }
    }
    #endif

    public nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.flushPendingSelection()
        }
    }

    public nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receiveMessage(message)
    }

    public nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        receiveMessage(applicationContext)
    }

    private nonisolated func receiveMessage(_ message: [String: Any]) {
        guard let selection = Self.decode(message) else { return }
        Task { @MainActor in
            self.receive(selection)
        }
    }
}

extension Logger {
    static let watchConnectivity = Logger(subsystem: "wonderboymusic.leadsheets", category: "WatchConnectivity")
}
#endif
