import SwiftUI

/// Centralized platform-specific colors for consistent styling across all platforms
struct PlatformColors {
    /// Background color for row cards with rounded corners and shadows
    static var rowBackground: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #elseif os(tvOS) || os(watchOS)
        return Color.white.opacity(0.1)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }

    /// Background color for placeholder icons (when no cover art/image is available)
    static var iconPlaceholder: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #elseif os(tvOS) || os(watchOS)
        return Color.gray.opacity(0.2)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
}
