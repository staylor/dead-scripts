#if os(iOS) || os(macOS)
import SwiftUI

struct PDFKitView: View {
    let url: URL

    var body: some View {
        #if os(iOS)
        GeometryReader { geometry in
            // The sheet runs under the glass bars, and the scroll view insets the page by their heights.
            PDFKitViewRepresentable(url: url, barInsets: geometry.safeAreaInsets)
                .ignoresSafeArea(.container, edges: .vertical)
        }
        #else
        PDFKitViewRepresentable(url: url)
        #endif
    }
}
#endif
