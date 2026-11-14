import SwiftUI

extension View {
    /// On the Mac, a back button and title above a list pushed in the library column. The column's own back button bar
    /// fills the whole column on macOS 27, which moves the list's rows below the window.
    @ViewBuilder
    func libraryBackBar(title: String) -> some View {
        #if os(macOS)
        modifier(LibraryBackBar(title: title))
        #else
        self
        #endif
    }
}

#if os(macOS)
private struct LibraryBackBar: ViewModifier {
    let title: String

    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden()
            .safeAreaBar(edge: .top) {
                HStack(spacing: 0) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                            .labelStyle(.iconOnly)
                            .frame(minWidth: 28, minHeight: 28, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.borderless)
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
    }
}
#endif
