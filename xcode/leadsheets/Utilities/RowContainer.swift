import SwiftUI

/// A view modifier that applies consistent row styling across list views.
struct RowContainer: ViewModifier {
    var showChevron: Bool = true
    var isSelected: Bool = false

    private var backgroundColor: Color {
        #if os(macOS)
        if isSelected {
            return Color.accentColor.opacity(0.05)
        }
        #endif
        return PlatformColors.rowBackground
    }

    func body(content: Content) -> some View {
        HStack(spacing: 16) {
            content

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

extension View {
    func rowContainer(showChevron: Bool = true, isSelected: Bool = false) -> some View {
        modifier(RowContainer(showChevron: showChevron, isSelected: isSelected))
    }
}
