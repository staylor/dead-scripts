import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct AlbumRowView: View {
    let album: Album
    
    // Helper function to load images
    #if canImport(UIKit)
    private func loadImage(named fileName: String) -> UIImage? {
        let justFileName = (fileName as NSString).lastPathComponent
        let fileNameWithoutExt = (justFileName as NSString).deletingPathExtension
        let ext = (justFileName as NSString).pathExtension
        
        if let image = UIImage(named: justFileName) {
            return image
        }
        
        if let path = Bundle.main.path(forResource: fileNameWithoutExt, ofType: ext),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        if let image = UIImage(named: fileName) {
            return image
        }
        
        return nil
    }
    #elseif canImport(AppKit)
    private func loadImage(named fileName: String) -> NSImage? {
        let justFileName = (fileName as NSString).lastPathComponent
        let fileNameWithoutExt = (justFileName as NSString).deletingPathExtension
        let ext = (justFileName as NSString).pathExtension
        
        if let image = NSImage(named: justFileName) {
            return image
        }
        
        if let path = Bundle.main.path(forResource: fileNameWithoutExt, ofType: ext),
           let image = NSImage(contentsOfFile: path) {
            return image
        }
        
        if let image = NSImage(named: fileName) {
            return image
        }
        
        return nil
    }
    #endif
    
    var body: some View {
        HStack(spacing: 16) {
            // Album Cover Art or Icon
            Group {
                if let coverArtFileName = album.coverArtFileName,
                   let loadedImage = loadImage(named: coverArtFileName) {
                    #if canImport(UIKit)
                    Image(uiImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    #elseif canImport(AppKit)
                    Image(nsImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    #endif
                } else {
                    Image(systemName: "opticaldisc")
                        .font(.system(size: 50))
                        .foregroundColor(.pink)
                        .frame(width: 80, height: 80)
                        #if os(iOS)
                        .background(Color(.systemGray6))
                        #else
                        .background(Color(nsColor: .controlBackgroundColor))
                        #endif
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
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
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
