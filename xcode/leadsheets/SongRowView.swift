import SwiftUI

struct SongRowView: View {
    let song: Song
    
    var body: some View {
        HStack(spacing: 16) {
            // Album Cover Art or Icon
            Group {
                if let album = song.album,
                   let coverArtFileName = album.coverArtFileName,
                   let loadedImage = ImageLoader.loadImage(named: coverArtFileName) {
                    #if canImport(UIKit)
                    Image(uiImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    #elseif canImport(AppKit)
                    Image(nsImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    #endif
                } else {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(.pink)
                        .frame(width: 60, height: 60)
                        .background(PlatformColors.iconPlaceholder)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
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
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(PlatformColors.rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
