import SwiftUI

#if os(macOS)
/// macOS-specific lyrics inspector view for displaying song lyrics in an inspector panel
struct LyricsInspector: View {
    let song: Song
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Lyrics")
                    .font(.title2)
                    .fontWeight(.bold)
                
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
    }
}
#endif
