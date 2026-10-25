import SwiftUI

#if os(macOS)
import DeadSheetsKit

/// macOS-specific lyrics inspector view for displaying song lyrics in an inspector panel
struct LyricsInspector: View {
    @ObservedObject private var musicPlayer = MusicPlayerService.shared
    let song: Song

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Lyrics")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let appleMusicId = song.appleMusicID {
                        let isThisSongPlaying = musicPlayer.isPlayingSong(appleMusicId)
                        let isThisSongLoading = musicPlayer.isLoadingSong(appleMusicId)
                        Spacer()
                        Button(action: {
                            if isThisSongPlaying {
                                musicPlayer.pause()
                            } else {
                                Task {
                                    await musicPlayer.play(appleMusicId: appleMusicId, songName: song.title)
                                }
                            }
                        }) {
                            HStack {
                                if isThisSongLoading {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: isThisSongPlaying ? "pause.fill" : "play.fill")
                                }
                                Text(isThisSongLoading ? "Loading..." : (isThisSongPlaying ? "Pause" : "Play"))
                            }
                            .padding(.vertical, 8)
                        }
                        .disabled(isThisSongLoading)
                    }
                }
                Divider()

                if !song.lyrics.isEmpty {
                    let lines = song.lyricLines
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(lines.indices, id: \.self) { index in
                            Text(lines[index])
                                .font(.body)
                                .foregroundColor(.primary)
                                .bold(Song.isChorusHeading(lines[index]))
                                .textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No lyrics available")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
    }
}
#endif
