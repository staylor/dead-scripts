import SwiftUI

struct SingerRowView: View {
    let singer: Singer

    var body: some View {
        HStack(spacing: 16) {
            // Singer Icon
            Group {
                if let imageFileName = singer.imageFileName,
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
                Text(singer.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let songCount = singer.songs?.count, songCount > 0 {
                    Text("\(songCount) song\(songCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
