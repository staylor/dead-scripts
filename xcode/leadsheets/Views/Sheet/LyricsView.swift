#if os(iOS) || os(macOS)
import DeadSheetsKit
import SwiftUI

struct LyricsView: View {
    let song: Song

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.title2)
                        .bold()
                    Text(song.creditsText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let singer = song.singer {
                        Text("Sung by \(singer.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                if song.lyrics.isEmpty {
                    ContentUnavailableView("No Lyrics", systemImage: "text.quote")
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(song.lyricParagraphs.enumerated()), id: \.offset) { _, paragraph in
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(Array(paragraph.enumerated()), id: \.offset) { _, line in
                                    Text(line)
                                        .bold(Song.isChorusHeading(line))
                                        .accessibilityAddTraits(Song.isChorusHeading(line) ? .isHeader : [])
                                }
                            }
                        }
                    }
                    .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

#Preview {
    if let song = Catalog.bundled.song(id: "ripple") {
        LyricsView(song: song)
    }
}
#endif
