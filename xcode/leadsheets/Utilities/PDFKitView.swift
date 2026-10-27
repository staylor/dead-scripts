import SwiftUI

#if !os(watchOS) && !os(tvOS)
import PDFKit

#if canImport(UIKit)
import UIKit
#endif

struct PDFKitView: View {
    let url: URL
    @State private var initialLoadComplete = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var isReturningFromBackground = false

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                #if os(iOS)
                // The sheet runs under the glass bars, and the scroll view insets the page by their heights.
                PDFKitViewRepresentable(
                    url: url,
                    size: geometry.size,
                    barInsets: geometry.safeAreaInsets,
                    initialLoadComplete: $initialLoadComplete,
                    isReturningFromBackground: $isReturningFromBackground
                )
                .ignoresSafeArea(.container, edges: .vertical)
                #else
                PDFKitViewRepresentable(
                    url: url,
                    size: geometry.size,
                    initialLoadComplete: $initialLoadComplete,
                    isReturningFromBackground: $isReturningFromBackground
                )
                #endif
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if oldPhase == .background && newPhase == .active {
                isReturningFromBackground = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isReturningFromBackground = false
                }
            }
        }
    }
}

#endif
