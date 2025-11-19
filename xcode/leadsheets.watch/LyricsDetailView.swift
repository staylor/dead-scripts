import SwiftUI

struct LyricsDetailView: View {
    let song: Song

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Song info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    if let artist = song.artist {
                        Text(artist.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let album = song.album {
                        Text(album.name)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.bottom, 8)

                Divider()

                // Lyrics
                if let lyrics = song.lyrics, !lyrics.isEmpty {
                    Text(lyrics)
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
