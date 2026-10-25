import DeadSheetsKit
import SwiftUI

struct SongRowView: View {
    let song: Song
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            CachedImage(
                fileName: song.coverFileName,
                size: 60,
                clipShape: RoundedRectangle(cornerRadius: 12)
            ) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 40))
                    .foregroundColor(.pink)
                    .frame(width: 60, height: 60)
                    .background(PlatformColors.iconPlaceholder)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(song.artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Text("•")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(song.albumTitle)
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .rowContainer(isSelected: isSelected)
    }
}
