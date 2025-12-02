import SwiftUI

struct ArtistRowView: View {
    let artist: Artist
    
    var body: some View {
        HStack(spacing: 16) {
            CachedImage(
                fileName: artist.imageFileName,
                size: 60,
                clipShape: Circle()
            ) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                    .frame(width: 60, height: 60)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let songCount = artist.songs?.count, songCount > 0 {
                        Text("\(songCount) song\(songCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let albumCount = artist.albums?.count, albumCount > 0 {
                        if artist.songs?.count ?? 0 > 0 {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("\(albumCount) album\(albumCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .rowContainer()
    }
}
