import SwiftUI

struct AlbumRowView: View {
    let album: Album
    
    var body: some View {
        HStack(spacing: 16) {
            CachedImage(
                fileName: album.coverArtFileName,
                size: 80,
                clipShape: RoundedRectangle(cornerRadius: 12)
            ) {
                Image(systemName: "opticaldisc")
                    .font(.system(size: 50))
                    .foregroundColor(.pink)
                    .frame(width: 80, height: 80)
                    .background(PlatformColors.iconPlaceholder)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if let artistName = album.artist?.name, !artistName.isEmpty {
                    Text(artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let songCount = album.songs?.count, songCount > 0 {
                    Text("\(songCount) song\(songCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .rowContainer()
    }
}
