#if os(iOS) || os(macOS)
import MusicKit
import SwiftUI

extension View {
    /// Presents playback failures and the Apple Music subscription offer.
    func playbackAlerts() -> some View {
        modifier(PlaybackAlerts())
    }
}

private struct PlaybackAlerts: ViewModifier {
    private let player = MusicPlayerService.shared
    @Environment(\.openURL) private var openURL

    func body(content: Content) -> some View {
        content
            .alert(isPresented: isShowingFailure, error: player.failure) { failure in
                if failure.reason == .notAuthorized {
                    Button("Open Settings") {
                        if let url = Self.settingsURL {
                            openURL(url)
                        }
                    }
                } else {
                    Button("Open in Apple Music") {
                        if let url = Self.appleMusicURL(for: failure.appleMusicID) {
                            openURL(url)
                        }
                    }
                }
                Button("OK", role: .cancel) {}
            } message: { failure in
                Text(failure.failureReason ?? "")
            }
            .musicSubscriptionOffer(isPresented: isShowingSubscriptionOffer, options: subscriptionOfferOptions)
    }

    private var isShowingFailure: Binding<Bool> {
        Binding(
            get: { player.failure != nil },
            set: { if !$0 { player.failure = nil } }
        )
    }

    private var isShowingSubscriptionOffer: Binding<Bool> {
        Binding(
            get: { player.subscriptionOfferSongID != nil },
            set: { if !$0 { player.subscriptionOfferSongID = nil } }
        )
    }

    private var subscriptionOfferOptions: MusicSubscriptionOffer.Options {
        var options = MusicSubscriptionOffer.Options()
        options.messageIdentifier = .playMusic
        options.itemID = player.subscriptionOfferSongID.map { MusicItemID($0) }
        return options
    }

    private static var settingsURL: URL? {
        #if os(macOS)
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Media")
        #else
        URL(string: UIApplication.openSettingsURLString)
        #endif
    }

    private static func appleMusicURL(for appleMusicID: String) -> URL? {
        #if os(macOS)
        URL(string: "music://music.apple.com/song/\(appleMusicID)")
        #else
        URL(string: "https://music.apple.com/song/\(appleMusicID)")
        #endif
    }
}
#endif
