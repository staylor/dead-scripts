#if os(iOS) || os(macOS)
import DeadSheetsKit
import SwiftUI

extension FocusedValues {
    @Entry var shownSong: Song?
    @Entry var showsLyrics: Binding<Bool>?
}

/// The Song menu on the Mac, and in the iPad menu bar and keyboard shortcut list.
struct SongCommands: Commands {
    @FocusedValue(\.shownSong) private var song
    @FocusedValue(\.showsLyrics) private var showsLyrics

    var body: some Commands {
        CommandMenu("Song") {
            PlayPauseCommand(song: song)

            Button(showsLyrics?.wrappedValue == true ? "Hide Lyrics" : "Show Lyrics") {
                showsLyrics?.wrappedValue.toggle()
            }
            .keyboardShortcut("l", modifiers: [.command, .option])
            .disabled(showsLyrics == nil)
        }
    }
}

private struct PlayPauseCommand: View {
    let song: Song?

    private let player = MusicPlayerService.shared

    var body: some View {
        let appleMusicID = song?.appleMusicID
        let isPlaying = appleMusicID.map(player.isPlayingSong) ?? false

        Button(isPlaying ? "Pause" : "Play in Apple Music") {
            guard let song, let appleMusicID else { return }
            if isPlaying {
                player.pause()
            } else {
                Task {
                    await player.play(appleMusicID: appleMusicID, title: song.title)
                }
            }
        }
        .keyboardShortcut("p", modifiers: [.command, .option])
        .disabled(appleMusicID == nil)
    }
}
#endif
