import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A utility for loading images from the app bundle across iOS and macOS platforms.
enum ImageLoader {
    
    #if canImport(UIKit)
    /// Loads a UIImage from the bundle by trying multiple lookup strategies.
    /// - Parameter fileName: The name of the image file to load (with or without path prefix)
    /// - Returns: A UIImage if found, nil otherwise
    static func loadImage(named fileName: String) -> UIImage? {
        // Try without directory prefix (most common if files are at root)
        let justFileName = (fileName as NSString).lastPathComponent
        let fileNameWithoutExt = (justFileName as NSString).deletingPathExtension
        let ext = (justFileName as NSString).pathExtension
        
        // First attempt: Image by just the filename
        if let image = UIImage(named: justFileName) {
            return image
        }
        
        // Second attempt: Load from file path in bundle
        if let path = Bundle.main.path(forResource: fileNameWithoutExt, ofType: ext),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        // Third attempt: Try with full path as fallback
        if let image = UIImage(named: fileName) {
            return image
        }
        
        return nil
    }
    
    #elseif canImport(AppKit)
    /// Loads an NSImage from the bundle by trying multiple lookup strategies.
    /// - Parameter fileName: The name of the image file to load (with or without path prefix)
    /// - Returns: An NSImage if found, nil otherwise
    static func loadImage(named fileName: String) -> NSImage? {
        let justFileName = (fileName as NSString).lastPathComponent
        let fileNameWithoutExt = (justFileName as NSString).deletingPathExtension
        let ext = (justFileName as NSString).pathExtension
        
        // First attempt: Image by just the filename
        if let image = NSImage(named: justFileName) {
            return image
        }
        
        // Second attempt: Load from file path in bundle
        if let path = Bundle.main.path(forResource: fileNameWithoutExt, ofType: ext),
           let image = NSImage(contentsOfFile: path) {
            return image
        }
        
        // Third attempt: Try with full path as fallback
        if let image = NSImage(named: fileName) {
            return image
        }
        
        return nil
    }
    #endif
}
