import Foundation
import Combine
#if os(iOS) || os(watchOS)
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var selectedSongID: String?

    private override init() {
        super.init()

        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func sendSelectedSong(songID: String, songName: String) {
        guard WCSession.default.activationState == .activated else { return }

        #if os(iOS)
        guard WCSession.default.isWatchAppInstalled else { return }
        #endif

        let message: [String: Any] = [
            "selectedSongID": songID,
            "selectedSongName": songName,
            "timestamp": Date().timeIntervalSince1970
        ]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("WatchConnectivity error: \(error.localizedDescription)")
            }
        }

        try? WCSession.default.updateApplicationContext(message)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let songID = message["selectedSongID"] as? String {
            DispatchQueue.main.async { [weak self] in
                self?.selectedSongID = songID
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let songID = applicationContext["selectedSongID"] as? String {
            DispatchQueue.main.async { [weak self] in
                self?.selectedSongID = songID
            }
        }
    }
}
#endif
