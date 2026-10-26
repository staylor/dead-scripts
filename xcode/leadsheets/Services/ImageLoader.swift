import Foundation

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

/// Album covers and band photos, which are bundled as loose files rather than in the asset catalog.
enum ImageLoader {
    private static let cache = NSCache<NSString, PlatformImage>()

    static func loadImage(named fileName: String) -> PlatformImage? {
        let key = fileName as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let url = Bundle.main.url(forResource: (fileName as NSString).lastPathComponent, withExtension: nil),
            let image = PlatformImage(contentsOfFile: url.path(percentEncoded: false))
        else {
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }
}
