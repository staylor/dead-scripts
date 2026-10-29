#if os(iOS) || os(watchOS)
import Foundation
import Observation
import os
import WatchConnectivity

/// Sends the selected song between iPhone and Apple Watch.
@MainActor
@Observable
public final class WatchConnectivityManager: NSObject {
    public static let shared = WatchConnectivityManager()

    /// The song most recently selected on the paired device. Selecting the same song again is a new selection.
    public private(set) var selection: Selection?

    public struct Selection: Equatable, Sendable {
        public let songID: Song.ID
        let timestamp: TimeInterval
    }

    override private init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    public func sendSelectedSong(id: Song.ID) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        #if os(iOS)
        guard session.isWatchAppInstalled else { return }
        #endif

        let message: [String: Any] = [
            MessageKey.songID: id,
            MessageKey.timestamp: Date().timeIntervalSince1970,
        ]
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { error in
                Logger.watchConnectivity.error("sendMessage failed: \(error.localizedDescription)")
            }
        }
        do {
            try session.updateApplicationContext(message)
        } catch {
            Logger.watchConnectivity.error("updateApplicationContext failed: \(error.localizedDescription)")
        }
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
    }

    #if os(iOS)
    public nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    public nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    public nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receive(message)
    }

    public nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        receive(applicationContext)
    }

    /// A selection arrives as a message and again as the application context, with the same timestamp.
    private nonisolated func receive(_ message: [String: Any]) {
        guard let songID = message[MessageKey.songID] as? String,
            let timestamp = message[MessageKey.timestamp] as? TimeInterval
        else { return }
        Task { @MainActor in
            self.selection = Selection(songID: songID, timestamp: timestamp)
        }
    }
}

extension Logger {
    static let watchConnectivity = Logger(subsystem: "wonderboymusic.leadsheets", category: "WatchConnectivity")
}
#endif
