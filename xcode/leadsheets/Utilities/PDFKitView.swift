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
                PDFKitViewRepresentable(
                    url: url,
                    size: geometry.size,
                    initialLoadComplete: $initialLoadComplete,
                    isReturningFromBackground: $isReturningFromBackground
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if oldPhase == .active && (newPhase == .inactive || newPhase == .background) {
                // App is going to background - we need to capture scroll position via a hack
                // since we don't have direct access to the PDFView here
                // The Coordinator will handle this in the representable
            } else if oldPhase == .background && newPhase == .active {
                // Mark that we're returning from background
                isReturningFromBackground = true
                // Reset flag after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isReturningFromBackground = false
                }
            }
        }
    }
}

#endif
