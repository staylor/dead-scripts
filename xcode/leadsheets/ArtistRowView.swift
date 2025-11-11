import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ArtistRowView: View {
    let artist: Artist
    
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
            // Artist Image or Icon
            Group {
                if let imageFileName = artist.imageFileName,
                   let loadedImage = loadImage(named: imageFileName) {
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
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
