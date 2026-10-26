#if os(iOS) || os(macOS)
import SwiftUI

extension View {
    /// Page turner pedals set to arrow keys change songs: left goes back, right goes forward. Page Up and
    /// Page Down are left to the sheet, so they scroll through a sheet with more than one page.
    func pageTurnerKeys(_ navigation: SongNavigation) -> some View {
        modifier(PageTurnerKeys(navigation: navigation))
    }
}

private struct PageTurnerKeys: ViewModifier {
    let navigation: SongNavigation

    #if os(macOS)
    @FocusState private var isFocused: Bool
    #endif

    func body(content: Content) -> some View {
        #if os(iOS)
        // Key commands don't need focus, which iPhone doesn't have, and text fields still get
        // their own arrow keys first.
        content.background {
            Group {
                Button("Previous Song") { navigation.previous?() }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    .disabled(navigation.previous == nil)
                Button("Next Song") { navigation.next?() }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                    .disabled(navigation.next == nil)
            }
            .hidden()
            .accessibilityHidden(true)
        }
        #else
        // Plain-key menu shortcuts would also fire in the sidebar, so the Mac only listens while the
        // sheet is focused, and has Command-[ and Command-] in the Song menu.
        content
            .focusable()
            .focusEffectDisabled()
            .focused($isFocused)
            .onKeyPress(.leftArrow) {
                run(navigation.previous)
            }
            .onKeyPress(.rightArrow) {
                run(navigation.next)
            }
            .onAppear {
                isFocused = true
            }
        #endif
    }

    #if os(macOS)
    private func run(_ action: (() -> Void)?) -> KeyPress.Result {
        guard let action else { return .ignored }
        action()
        return .handled
    }
    #endif
}
#endif
