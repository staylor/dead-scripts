import Combine
import Foundation
import MusicKit
import Observation
import os

struct PlaybackFailure: LocalizedError, Equatable, Sendable {
    enum Reason: Equatable, Sendable {
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

enum PlaybackResult: Equatable, Sendable {
    case cancelled
    case playing
    case needsSubscription
    case failed(PlaybackFailure)
}

/// Plays songs from the Apple Music catalog, and mirrors the system player's state so controls stay
/// correct when playback changes elsewhere (Control Center, CarPlay, the song ending).
@Observable
final class MusicPlayerService {
    static let shared = MusicPlayerService(observesPlayer: true)

    private(set) var isPlaying = false
    private(set) var currentSongID: String?
    private(set) var loadingSongID: String?
    /// Shown as an alert by the app's root view.
    var failure: PlaybackFailure?
    /// Set when someone who could subscribe tries to play a song; the root view presents the offer.
    var subscriptionOfferSongID: String?

    @ObservationIgnored private var playerObservation: AnyCancellable?
    @ObservationIgnored private var playbackRequest: (id: UUID, task: Task<PlaybackResult, Never>)?

    private let observesPlayer: Bool
    private let startPlayback: (String, String) async -> PlaybackResult
    private let pausePlayback: () -> Void

    init(
        observesPlayer: Bool = false,
        startPlayback: @escaping (String, String) async -> PlaybackResult = MusicPlayerService.performStart,
        pausePlayback: @escaping () -> Void = { ApplicationMusicPlayer.shared.pause() }
    ) {
        self.observesPlayer = observesPlayer
        self.startPlayback = startPlayback
        self.pausePlayback = pausePlayback
        guard observesPlayer else { return }
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

    func isPlayingSong(_ appleMusicID: String) -> Bool {
        isPlaying && currentSongID == appleMusicID
    }

    func isLoadingSong(_ appleMusicID: String) -> Bool {
        loadingSongID == appleMusicID
    }

    /// Plays the song, reporting problems through `failure` and `subscriptionOfferSongID`.
    func play(appleMusicID: String, title: String) async {
        switch await start(appleMusicID: appleMusicID, title: title) {
        case .playing, .cancelled:
            break
        case .needsSubscription:
            subscriptionOfferSongID = appleMusicID
        case .failed(let failure):
            self.failure = failure
        }
    }

    func start(appleMusicID: String, title: String) async -> PlaybackResult {
        let previous = playbackRequest?.task
        previous?.cancel()
        let id = UUID()
        loadingSongID = appleMusicID
        failure = nil
        subscriptionOfferSongID = nil
        let task = Task<PlaybackResult, Never> {
            // MusicKit can finish a cancelled play call; its cleanup must not pause the next request.
            _ = await previous?.value
            guard !Task.isCancelled else { return .cancelled }
            let result = await startPlayback(appleMusicID, title)
            if Task.isCancelled {
                pausePlayback()
                return .cancelled
            }
            return result
        }
        playbackRequest = (id, task)
        defer {
            if playbackRequest?.id == id {
                playbackRequest = nil
                loadingSongID = nil
            }
            syncWithPlayer()
        }
        let result = await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        return playbackRequest?.id == id && !task.isCancelled ? result : .cancelled
    }

    private static func performStart(appleMusicID: String, title: String) async -> PlaybackResult {
        let player = ApplicationMusicPlayer.shared

        func failed(_ reason: PlaybackFailure.Reason) -> PlaybackResult {
            Logger.music.error("Couldn't play \(appleMusicID, privacy: .public): \(String(describing: reason), privacy: .public)")
            return .failed(PlaybackFailure(songTitle: title, appleMusicID: appleMusicID, reason: reason))
        }

        if case .song(let current)? = player.queue.currentEntry?.item,
            current.id.rawValue == appleMusicID, player.state.playbackStatus != .playing
        {
            do {
                try await player.play()
                return .playing
            } catch {
                guard !Task.isCancelled else { return .cancelled }
                Logger.music.info(
                    "Resuming \(appleMusicID, privacy: .public) failed, restarting: \(error.localizedDescription, privacy: .public)")
            }
        }

        let authorization = await MusicAuthorization.request()
        guard !Task.isCancelled else { return .cancelled }
        guard authorization == .authorized else {
            return failed(.notAuthorized)
        }

        do {
            let subscription = try await MusicSubscription.current
            try Task.checkCancellation()
            guard subscription.canPlayCatalogContent else {
                return subscription.canBecomeSubscriber ? .needsSubscription : failed(.noSubscription)
            }

            let request = MusicCatalogResourceRequest<MusicKit.Song>(matching: \.id, equalTo: MusicItemID(appleMusicID))
            let songs = try await request.response().items
            try Task.checkCancellation()
            guard let song = songs.first else {
                return failed(.notInCatalog)
            }
            player.queue = [song]
            try await player.play()
            return .playing
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return failed(.other(error.localizedDescription))
        }
    }

    func pause() {
        playbackRequest?.task.cancel()
        loadingSongID = nil
        pausePlayback()
        syncWithPlayer()
    }

    private func syncWithPlayer() {
        guard observesPlayer else { return }
        let player = ApplicationMusicPlayer.shared
        isPlaying = player.state.playbackStatus == .playing
        if case .song(let song)? = player.queue.currentEntry?.item {
            currentSongID = song.id.rawValue
        } else {
            currentSongID = nil
        }
    }
}
