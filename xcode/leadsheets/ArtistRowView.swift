import SwiftUI

struct ArtistRowView: View {
    let artist: Artist
    
    var body: some View {
        HStack(spacing: 16) {
            // Artist Image or Icon
            Group {
                if let imageFileName = artist.imageFileName,
                   let loadedImage = ImageLoader.loadImage(named: imageFileName) {
                    #if canImport(UIKit)
                    Image(uiImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    #elseif canImport(AppKit)
                    Image(nsImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    #endif
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                        .frame(width: 60, height: 60)
                }
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
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        #if os(iOS)
        .background(Color(.systemBackground))
        #elseif os(tvOS) || os(watchOS)
        .background(Color.white.opacity(0.1))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
