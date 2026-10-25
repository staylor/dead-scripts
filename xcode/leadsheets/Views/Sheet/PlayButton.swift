#if os(iOS) || os(macOS)
import SwiftUI

struct PlayButton: View {
    let appleMusicID: String
    let title: String

    private let player = MusicPlayerService.shared

    var body: some View {
        let isPlaying = player.isPlayingSong(appleMusicID)
        let isLoading = player.isLoadingSong(appleMusicID)

        Button {
            if isPlaying {
                player.pause()
            } else {
                Task {
                    await player.play(appleMusicID: appleMusicID, title: title)
                }
            }
        } label: {
            if isLoading {
                ProgressView()
            } else {
                Label(isPlaying ? "Pause" : "Play in Apple Music", systemImage: isPlaying ? "pause.fill" : "play.fill")
            }
        }
        .disabled(isLoading)
    }
}
#endif
