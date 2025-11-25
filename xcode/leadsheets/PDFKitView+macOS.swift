import SwiftUI

#if os(macOS)
import PDFKit
import AppKit

extension PDFKitView {
    struct PDFKitViewRepresentable: NSViewRepresentable {
        let url: URL
        let size: CGSize
        @Binding var initialLoadComplete: Bool
        @Binding var isReturningFromBackground: Bool

        func makeNSView(context: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.autoScales = false
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical

            // Set white background for PDFView
            pdfView.backgroundColor = NSColor.white

            // Remove all shadows
            pdfView.layer?.shadowOpacity = 0
            pdfView.layer?.shadowRadius = 0
            pdfView.layer?.shadowOffset = CGSize.zero

            // Remove page shadows
            pdfView.pageShadowsEnabled = false

            // Load PDF document
            if let document = PDFKit.PDFDocument(url: url) {
                pdfView.document = document

                // Use a small delay to ensure pdfView has a proper frame
                DispatchQueue.main.async {
                    self.updateScaleFactor(for: pdfView, width: size.width, resetPosition: true)
                    self.initialLoadComplete = true
                    context.coordinator.lastSize = size
                }
            }

            return pdfView
        }

        func updateNSView(_ pdfView: PDFView, context: Context) {
            // Check if we need to load a different PDF
            if pdfView.document?.documentURL != url {
                if let document = PDFKit.PDFDocument(url: url) {
                    pdfView.document = document
                    DispatchQueue.main.async {
                        self.updateScaleFactor(for: pdfView, width: size.width, resetPosition: true)
                        self.initialLoadComplete = true
                        context.coordinator.lastSize = size
                    }
                }
            } else if initialLoadComplete {
                // Only update scale if size has actually changed significantly
                let sizeChanged = abs(context.coordinator.lastSize.width - size.width) > 1.0 ||
                                 abs(context.coordinator.lastSize.height - size.height) > 1.0

                if sizeChanged {
                    updateScaleFactor(for: pdfView, width: size.width, resetPosition: false)
                    context.coordinator.lastSize = size
                }
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        class Coordinator {
            var lastSize: CGSize = .zero
        }

        // MARK: - Helper Methods

        private func updateScaleFactor(for pdfView: PDFView, width: CGFloat, resetPosition: Bool) {
            guard let document = pdfView.document,
                  let page = document.page(at: 0) else { return }

            let pageSize = page.bounds(for: .mediaBox).size

            guard width > 0 else { return }

            let scaleToFit = width / pageSize.width

            guard resetPosition || abs(pdfView.scaleFactor - scaleToFit) > 0.01 else { return }

            pdfView.scaleFactor = scaleToFit
            pdfView.minScaleFactor = scaleToFit
            pdfView.maxScaleFactor = scaleToFit * 4.0

            // Always go to first page to keep at top
            pdfView.go(to: page)

            // Force scroll to top and adjust documentView position
            DispatchQueue.main.async {
                if let scrollView = pdfView.enclosingScrollView,
                   let documentView = pdfView.documentView {
                    // Reset documentView frame to align at top
                    var frame = documentView.frame
                    frame.origin.y = 0
                    documentView.frame = frame

                    // Scroll to top
                    scrollView.contentView.scroll(to: .zero)
                    scrollView.reflectScrolledClipView(scrollView.contentView)
                }
            }
        }
    }
}

#endif
