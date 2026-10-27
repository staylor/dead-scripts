import SwiftUI

#if !os(watchOS) && !os(tvOS)
import PDFKit

#if canImport(UIKit)
import UIKit
#endif

struct PDFKitView: View {
    let url: URL
    #if os(macOS)
    @State private var initialLoadComplete = false
    #endif

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                #if os(iOS)
                // The sheet runs under the glass bars, and the scroll view insets the page by their heights.
                PDFKitViewRepresentable(url: url, barInsets: geometry.safeAreaInsets)
                    .ignoresSafeArea(.container, edges: .vertical)
                #else
                PDFKitViewRepresentable(url: url, size: geometry.size, initialLoadComplete: $initialLoadComplete)
                #endif
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#endif
