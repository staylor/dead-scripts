import SwiftUI

struct GroupedWriterRowView: View {
    let groupedWriter: GroupedWriter
    
    var body: some View {
        HStack(spacing: 16) {
            // Writer Image or Icon
            Group {
                if let imageFileName = groupedWriter.imageFileName,
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
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                        .frame(width: 60, height: 60)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(groupedWriter.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(groupedWriter.displayContribution)
                        .font(.caption)
                        .foregroundColor(.pink)
                    
                    let songCount = groupedWriter.songs.count
                    if songCount > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(songCount) song\(songCount == 1 ? "" : "s")")
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
        .background(PlatformColors.rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
