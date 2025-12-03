import Combine
import Foundation
import MusicKit

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A shared service for playing songs via MusicKit across all platforms
@MainActor
class MusicPlayerService: ObservableObject {
    static let shared = MusicPlayerService()

    @Published private(set) var isPlaying = false
    @Published private(set) var isLoading = false
    @Published private(set) var loadingSongId: String?
    @Published private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published private(set) var currentSongId: String?

    private init() {
        Task {
            authorizationStatus = MusicAuthorization.currentStatus
        }
    }

    /// Request MusicKit authorization
    func requestAuthorization() async -> MusicAuthorization.Status {
        authorizationStatus = await MusicAuthorization.request()
        return authorizationStatus
    }

    /// Play a song by its Apple Music ID
    /// - Parameters:
    ///   - appleMusicId: The Apple Music catalog ID
    ///   - songName: The song name (for logging)
    func play(appleMusicId: String, songName: String) async {
        guard !appleMusicId.isEmpty else {
            print("MusicPlayerService: No Apple Music ID provided")
            return
        }

        let player = ApplicationMusicPlayer.shared

        // If resuming the same song, just call play
        if currentSongId == appleMusicId && !isPlaying {
            print("MusicPlayerService: Resuming \(songName)")
            isLoading = true
            loadingSongId = appleMusicId
            defer {
                isLoading = false
                loadingSongId = nil
            }
            do {
                try await player.play()
                isPlaying = true
                return
            } catch {
                print("MusicPlayerService: Resume failed, will restart: \(error)")
            }
        }

        // Set loading state
        isLoading = true
        loadingSongId = appleMusicId
        defer {
            isLoading = false
            loadingSongId = nil
        }

        print("MusicPlayerService: Attempting to play \(songName) (ID: \(appleMusicId))")
        print("MusicPlayerService: Current authorization status: \(authorizationStatus)")

        // Check/request authorization
        if authorizationStatus != .authorized {
            print("MusicPlayerService: Requesting authorization...")
            authorizationStatus = await MusicAuthorization.request()
            print("MusicPlayerService: Authorization result: \(authorizationStatus)")
        }

        guard authorizationStatus == .authorized else {
            print("MusicPlayerService: Not authorized (\(authorizationStatus)), falling back to URL")
            openAppleMusicURL(id: appleMusicId)
            return
        }

        do {
            // Fetch the song from Apple Music catalog
            print("MusicPlayerService: Fetching song from catalog...")
            let request = MusicCatalogResourceRequest<MusicKit.Song>(
                matching: \.id,
                equalTo: MusicItemID(appleMusicId)
            )
            let response = try await request.response()

            guard let song = response.items.first else {
                print("MusicPlayerService: Song not found in catalog (ID: \(appleMusicId))")
                openAppleMusicURL(id: appleMusicId)
                return
            }

            print("MusicPlayerService: Found song: \(song.title)")

            // Play the song
            player.queue = [song]
            print("MusicPlayerService: Starting playback...")
            try await player.play()
            currentSongId = appleMusicId
            isPlaying = true
            print("MusicPlayerService: Now playing \(songName)")
        } catch {
            print("MusicPlayerService: Playback error - \(error)")
            print("MusicPlayerService: Error details - \(String(describing: error))")
            openAppleMusicURL(id: appleMusicId)
        }
    }

    /// Stop playback
    func stop() {
        ApplicationMusicPlayer.shared.stop()
        isPlaying = false
        currentSongId = nil
    }

    /// Pause playback
    func pause() {
        ApplicationMusicPlayer.shared.pause()
        isPlaying = false
    }

    /// Check if a specific song is currently playing
    func isPlayingSong(_ appleMusicId: String?) -> Bool {
        guard let appleMusicId = appleMusicId, !appleMusicId.isEmpty else { return false }
        return isPlaying && currentSongId == appleMusicId
    }

    /// Check if a specific song is currently loading
    func isLoadingSong(_ appleMusicId: String?) -> Bool {
        guard let appleMusicId = appleMusicId, !appleMusicId.isEmpty else { return false }
        return isLoading && loadingSongId == appleMusicId
    }

    // MARK: - Private

    private func openAppleMusicURL(id appleMusicId: String) {
        let urlString = "music://music.apple.com/song/\(appleMusicId)"
        guard let url = URL(string: urlString) else { return }

        #if os(iOS)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let webURL = URL(string: "https://music.apple.com/song/\(appleMusicId)") {
            UIApplication.shared.open(webURL)
        }
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}
