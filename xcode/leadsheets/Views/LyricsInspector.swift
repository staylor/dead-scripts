import SwiftUI

#if os(macOS)
import SwiftData

/// macOS-specific lyrics inspector view for displaying song lyrics in an inspector panel
struct LyricsInspector: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var musicPlayer = MusicPlayerService.shared
    let songID: PersistentIdentifier

    private var song: Song? {
        modelContext.model(for: songID) as? Song
    }
    
    var body: some View {
        Group {
            if let song = song {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack {
                            Text("Lyrics")
                                .font(.title2)
                                .fontWeight(.bold)

                            // Apple Music Button
                            if let appleMusicId = song.appleMusicId, !appleMusicId.isEmpty {
                                let isThisSongPlaying = musicPlayer.isPlayingSong(appleMusicId)
                                let isThisSongLoading = musicPlayer.isLoadingSong(appleMusicId)
                                Spacer()
                                Button(action: {
                                    if isThisSongPlaying {
                                        musicPlayer.pause()
                                    } else {
                                        Task {
                                            await musicPlayer.play(appleMusicId: appleMusicId, songName: song.name)
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
                    
                        
                        // Lyrics Content
                        if let lyrics = song.lyrics, !lyrics.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(lyrics.components(separatedBy: "\n").enumerated()), id: \.offset) { index, line in
                                    Text(line)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .bold(line.hasPrefix("Chorus"))
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
            } else {
                ContentUnavailableView(
                    "Song Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text("The selected song could not be loaded")
                )
            }
        }
    }
}
#endif
