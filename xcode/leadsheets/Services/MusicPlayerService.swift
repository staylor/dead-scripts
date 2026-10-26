import Combine
import Foundation
import MusicKit
import Observation
import os

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PlaybackFailure: LocalizedError {
    enum Reason: Equatable {
        case notAuthorized
        case notInCatalog
        case noSubscription
        case other(String)
    }

    let songTitle: String
    let appleMusicID: String
    let reason: Reason

    var errorDescription: String? {
        "Couldn’t Play “\(songTitle)”"
    }

    var failureReason: String? {
        switch reason {
        case .notAuthorized:
            "Dead Sheets needs access to Apple Music. You can allow it in Settings."
        case .notInCatalog:
            "This recording isn’t available in Apple Music in your country or region."
        case .noSubscription:
            "Playing songs requires an Apple Music subscription."
        case .other(let message):
            message
        }
    }
}

enum PlaybackResult {
    case playing
    case needsSubscription
    case failed(PlaybackFailure)
}

/// Plays songs from the Apple Music catalog, and mirrors the system player's state so controls stay
/// correct when playback changes elsewhere (Control Center, CarPlay, the song ending).
@Observable
final class MusicPlayerService {
    static let shared = MusicPlayerService()

    private(set) var isPlaying = false
    private(set) var currentSongID: String?
    private(set) var loadingSongID: String?
    /// Shown as an alert by the app's root view.
    var failure: PlaybackFailure?
    /// Set when someone who could subscribe tries to play a song; the root view presents the offer.
    var subscriptionOfferSongID: String?

    @ObservationIgnored private var playerObservation: AnyCancellable?

    private init() {
        let player = ApplicationMusicPlayer.shared
        // objectWillChange fires before the player updates, so read its state on the next pass.
        playerObservation = Publishers.Merge(
            player.state.objectWillChange.map { _ in },
            player.queue.objectWillChange.map { _ in }
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] in
            self?.syncWithPlayer()
        }
        syncWithPlayer()
    }

    func requestAuthorization() async {
        _ = await MusicAuthorization.request()
    }

    func isPlayingSong(_ appleMusicID: String) -> Bool {
        isPlaying && currentSongID == appleMusicID
    }

    func isLoadingSong(_ appleMusicID: String) -> Bool {
        loadingSongID == appleMusicID
    }

    /// Plays the song, reporting problems through `failure` and `subscriptionOfferSongID`.
    func play(appleMusicID: String, title: String) async {
        switch await start(appleMusicID: appleMusicID, title: title) {
        case .playing:
            break
        case .needsSubscription:
            subscriptionOfferSongID = appleMusicID
        case .failed(let failure):
            self.failure = failure
        }
    }

    func start(appleMusicID: String, title: String) async -> PlaybackResult {
        let player = ApplicationMusicPlayer.shared
        loadingSongID = appleMusicID
        defer {
            loadingSongID = nil
            syncWithPlayer()
        }

        func failed(_ reason: PlaybackFailure.Reason) -> PlaybackResult {
            Logger.music.error("Couldn't play \(appleMusicID, privacy: .public): \(String(describing: reason), privacy: .public)")
            return .failed(PlaybackFailure(songTitle: title, appleMusicID: appleMusicID, reason: reason))
        }

        if currentSongID == appleMusicID && !isPlaying {
            do {
                try await player.play()
                return .playing
            } catch {
                Logger.music.info(
                    "Resuming \(appleMusicID, privacy: .public) failed, restarting: \(error.localizedDescription, privacy: .public)")
            }
        }

        guard await MusicAuthorization.request() == .authorized else {
            return failed(.notAuthorized)
        }

        do {
            let subscription = try await MusicSubscription.current
            guard subscription.canPlayCatalogContent else {
                return subscription.canBecomeSubscriber ? .needsSubscription : failed(.noSubscription)
            }

            let request = MusicCatalogResourceRequest<MusicKit.Song>(matching: \.id, equalTo: MusicItemID(appleMusicID))
            guard let song = try await request.response().items.first else {
                return failed(.notInCatalog)
            }
            player.queue = [song]
            try await player.play()
            return .playing
        } catch {
            return failed(.other(error.localizedDescription))
        }
    }

    func pause() {
        ApplicationMusicPlayer.shared.pause()
        syncWithPlayer()
    }

    func openInAppleMusic(_ appleMusicID: String) {
        #if os(macOS)
        if let url = URL(string: "music://music.apple.com/song/\(appleMusicID)") {
            NSWorkspace.shared.open(url)
        }
        #else
        if let url = URL(string: "https://music.apple.com/song/\(appleMusicID)") {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private func syncWithPlayer() {
        let player = ApplicationMusicPlayer.shared
        isPlaying = player.state.playbackStatus == .playing
        if case .song(let song)? = player.queue.currentEntry?.item {
            currentSongID = song.id.rawValue
        } else {
            currentSongID = nil
        }
    }
}
