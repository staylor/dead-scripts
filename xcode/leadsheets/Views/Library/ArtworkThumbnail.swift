import MusicKit
import SwiftUI

/// A square cover or round photo from Apple Music, with a symbol when there's none.
struct ArtworkThumbnail: View {
    let appleMusicID: String?
    let placeholder: String
    var isPortrait = false

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = ArtworkThumbnail.defaultSize

    var body: some View {
        Group {
            if let artwork = ArtworkStore.shared.artwork(for: appleMusicID) {
                ArtworkImage(artwork, width: size, height: size)
            } else {
                Image(systemName: placeholder)
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.fill.tertiary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(isPortrait ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: size * 0.15)))
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
