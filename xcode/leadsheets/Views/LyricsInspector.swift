import SwiftUI

#if os(macOS)
import SwiftData

/// macOS-specific lyrics inspector view for displaying song lyrics in an inspector panel
struct LyricsInspector: View {
    @Environment(\.modelContext) private var modelContext
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
                                Spacer()
                                Button(action: {
                                    openAppleMusic(songId: appleMusicId)
                                }) {
                                    HStack {
                                        Image(systemName: "applelogo")
                                        Text("Play on Apple Music")
                                    }
                                    .padding(.vertical, 8)
                                }
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
    
    // MARK: - Helper Methods
    
    private func openAppleMusic(songId: String) {
        // Try to open in Apple Music app
        if let url = URL(string: "music://music.apple.com/song/\(songId)") {
            NSWorkspace.shared.open(url)
        }
    }
}
#endif
