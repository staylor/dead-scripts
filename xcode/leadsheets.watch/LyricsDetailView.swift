import DeadSheetsKit
import SwiftUI

struct LyricsDetailView: View {
    let song: Song

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Song info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(song.artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(song.albumTitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(song.creditsText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)

                Divider()

                // Lyrics
                if !song.lyrics.isEmpty {
                    Text(song.lyrics)
                        .font(.caption)
                        .lineSpacing(4)
                } else {
                    Text("No lyrics available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            .padding()
        }
        .navigationTitle("Lyrics")
        .navigationBarTitleDisplayMode(.inline)
    }
}
