import SwiftUI

struct SongRowView: View {
    let song: Song
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            CachedImage(
                fileName: song.album?.coverArtFileName,
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
                Text(song.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if let artistName = song.artist?.name, !artistName.isEmpty {
                    HStack(spacing: 4) {
                        Text(artistName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        if let albumName = song.album?.name, !albumName.isEmpty {
                            Text("•")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(albumName)
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                } else if let albumName = song.album?.name, !albumName.isEmpty {
                    Text(albumName)
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
