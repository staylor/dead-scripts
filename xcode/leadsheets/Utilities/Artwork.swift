import SwiftUI

/// A square cover or round photo from the app bundle, with a symbol when the file is missing.
struct Artwork: View {
    enum Style {
        case cover
        case portrait
    }

    let fileName: String?
    let placeholder: String
    var style: Style = .cover

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = Artwork.defaultSize

    var body: some View {
        Group {
            if let fileName, let image = ImageLoader.loadImage(named: fileName) {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: placeholder)
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.fill.tertiary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(style == .portrait ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: size * 0.15)))
        .accessibilityHidden(true)
    }

    private static var defaultSize: CGFloat {
        #if os(macOS)
        32
        #elseif os(tvOS)
        80
        #else
        48
        #endif
    }
}

extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}
