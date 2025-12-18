import Foundation

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

/// A utility for loading images from the app bundle across iOS and macOS platforms.
/// Images are cached in memory to avoid repeated disk I/O.
enum ImageLoader {
    private static let cache = NSCache<NSString, PlatformImage>()

    /// Loads an image from the bundle by trying multiple lookup strategies.
    /// Results are cached in memory for fast subsequent access.
    /// - Parameter fileName: The name of the image file to load (with or without path prefix)
    /// - Returns: A platform-specific image if found, nil otherwise
    static func loadImage(named fileName: String) -> PlatformImage? {
        let key = fileName as NSString

        // Return cached image if available
        if let cached = cache.object(forKey: key) {
            return cached
        }

        // Try without directory prefix (most common if files are at root)
        let justFileName = (fileName as NSString).lastPathComponent
        let fileNameWithoutExt = (justFileName as NSString).deletingPathExtension
        let ext = (justFileName as NSString).pathExtension

        let image: PlatformImage? = loadFromBundle(
            justFileName: justFileName,
            fileNameWithoutExt: fileNameWithoutExt,
            ext: ext,
            fullPath: fileName
        )

        // Cache the result
        if let image {
            cache.setObject(image, forKey: key)
        }

        return image
    }

    private static func loadFromBundle(
        justFileName: String,
        fileNameWithoutExt: String,
        ext: String,
        fullPath: String
    ) -> PlatformImage? {
        #if canImport(UIKit)
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
        if let image = UIImage(named: fullPath) {
            return image
        }
        #elseif canImport(AppKit)
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
        if let image = NSImage(named: fullPath) {
            return image
        }
        #endif

        return nil
    }
}
