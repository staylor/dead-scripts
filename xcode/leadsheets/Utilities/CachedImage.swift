import SwiftUI

/// A reusable view for displaying cached images with a placeholder fallback.
/// Handles cross-platform differences between UIKit and AppKit.
struct CachedImage<Placeholder: View, ClipShape: Shape>: View {
    let fileName: String?
    let size: CGFloat
    let clipShape: ClipShape
    let placeholder: Placeholder

    init(
        fileName: String?,
        size: CGFloat,
        clipShape: ClipShape,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.fileName = fileName
        self.size = size
        self.clipShape = clipShape
        self.placeholder = placeholder()
    }

    var body: some View {
        if let fileName, let image = ImageLoader.loadImage(named: fileName) {
            imageView(for: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(clipShape)
        } else {
            placeholder
        }
    }

    private func imageView(for image: PlatformImage) -> Image {
        #if canImport(UIKit)
        Image(uiImage: image)
        #elseif canImport(AppKit)
        Image(nsImage: image)
        #endif
    }
}
