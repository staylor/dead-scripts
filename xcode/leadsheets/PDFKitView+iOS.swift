import SwiftUI

#if !os(watchOS) && !os(tvOS)
import PDFKit

#if os(iOS) || os(tvOS)
import UIKit

// MARK: - iOS Implementation

extension PDFKitView {
    struct PDFKitViewRepresentable: UIViewRepresentable {
        let url: URL
        let size: CGSize
        @Binding var initialLoadComplete: Bool
        @Binding var isReturningFromBackground: Bool

        func makeUIView(context: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.autoScales = false  // Turn off autoScales to manually control width
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical

            // Set white background for PDFView
            pdfView.backgroundColor = UIColor.white

            // Remove all shadows
            pdfView.layer.shadowOpacity = 0
            pdfView.layer.shadowRadius = 0
            pdfView.layer.shadowOffset = CGSize.zero

            // Remove page shadows by setting page shadow to transparent
            pdfView.pageShadowsEnabled = false

            // Load PDF document
            if let document = PDFKit.PDFDocument(url: url) {
                pdfView.document = document

                // Use a small delay to ensure pdfView has a proper frame
                DispatchQueue.main.async {
                    self.updateScaleFactor(for: pdfView, width: size.width, resetPosition: true, context: context)
                    self.initialLoadComplete = true
                    context.coordinator.lastSize = size

                    // Lock zoom scale after setting PDFView's scaleFactor
                    // This prevents user pinch-to-zoom but allows our scaleFactor to work
                    if let scrollView = pdfView.subviews.first as? UIScrollView {
                        let currentZoom = scrollView.zoomScale
                        scrollView.maximumZoomScale = currentZoom
                        scrollView.minimumZoomScale = currentZoom
                        scrollView.bouncesZoom = false
                        context.coordinator.lastZoomScale = currentZoom
                    }
                }
            }

            return pdfView
        }

        func updateUIView(_ pdfView: PDFView, context: Context) {
            // Capture scroll position before any potential changes
            if let scrollView = pdfView.subviews.first as? UIScrollView {
                if !isReturningFromBackground {
                    context.coordinator.lastScrollOffset = scrollView.contentOffset
                }
            }

            // If returning from background, force the scale factor back and lock it
            if isReturningFromBackground {
                if context.coordinator.lastPDFScaleFactor > 0 {
                    // Restore scale factor first (allow this to work normally)
                    pdfView.scaleFactor = context.coordinator.lastPDFScaleFactor
                    pdfView.minScaleFactor = context.coordinator.lastPDFScaleFactor
                    pdfView.maxScaleFactor = context.coordinator.lastPDFScaleFactor * 4.0

                    if let scrollView = pdfView.subviews.first as? UIScrollView {
                        scrollView.zoomScale = context.coordinator.lastZoomScale
                        scrollView.maximumZoomScale = context.coordinator.lastZoomScale
                        scrollView.minimumZoomScale = context.coordinator.lastZoomScale

                        // Restore scroll position without animation
                        UIView.performWithoutAnimation {
                            scrollView.setContentOffset(context.coordinator.lastScrollOffset, animated: false)
                        }
                    }

                    // Keep forcing it for a bit to override any PDFKit layout passes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        pdfView.scaleFactor = context.coordinator.lastPDFScaleFactor
                        pdfView.minScaleFactor = context.coordinator.lastPDFScaleFactor
                        pdfView.maxScaleFactor = context.coordinator.lastPDFScaleFactor * 4.0

                        if let scrollView = pdfView.subviews.first as? UIScrollView {
                            scrollView.zoomScale = context.coordinator.lastZoomScale
                            scrollView.maximumZoomScale = context.coordinator.lastZoomScale
                            scrollView.minimumZoomScale = context.coordinator.lastZoomScale

                            // Restore scroll position again without animation
                            UIView.performWithoutAnimation {
                                scrollView.setContentOffset(context.coordinator.lastScrollOffset, animated: false)
                            }
                        }
                    }
                }
                return
            }

            // Check if we need to load a different PDF
            if pdfView.document?.documentURL != url {
                if let document = PDFKit.PDFDocument(url: url) {
                    pdfView.document = document
                    DispatchQueue.main.async {
                        self.updateScaleFactor(for: pdfView, width: size.width, resetPosition: true, context: context)
                        self.initialLoadComplete = true
                        context.coordinator.lastSize = size

                        // Lock zoom to current scale after loading
                        if let scrollView = pdfView.subviews.first as? UIScrollView {
                            let currentZoom = scrollView.zoomScale
                            scrollView.maximumZoomScale = currentZoom
                            scrollView.minimumZoomScale = currentZoom
                            context.coordinator.lastZoomScale = currentZoom
                            context.coordinator.lastScrollOffset = scrollView.contentOffset
                        }
                        context.coordinator.lastPDFScaleFactor = pdfView.scaleFactor
                    }
                }
            } else if initialLoadComplete {
                // Only update scale if size has actually changed significantly
                let widthChanged = abs(context.coordinator.lastSize.width - size.width) > 1.0
                let heightChanged = abs(context.coordinator.lastSize.height - size.height) > 1.0
                let sizeChanged = widthChanged || heightChanged

                if sizeChanged {
                    // Explicitly set PDFView's frame to match new size
                    pdfView.frame = CGRect(origin: .zero, size: size)

                    // Save current page before orientation change
                    let currentPage = pdfView.currentPage

                    // Reset scroll view zoom to 1.0 first
                    if let scrollView = pdfView.subviews.first as? UIScrollView {
                        scrollView.maximumZoomScale = 10.0
                        scrollView.minimumZoomScale = 0.1
                        scrollView.setZoomScale(1.0, animated: false)
                    }

                    // Calculate and force update scale factor for new width
                    if let document = pdfView.document,
                       let firstPage = document.page(at: 0) {
                        let pageSize = firstPage.bounds(for: .mediaBox).size
                        let scaleToFit = size.width / pageSize.width

                        pdfView.scaleFactor = scaleToFit
                        pdfView.minScaleFactor = scaleToFit
                        pdfView.maxScaleFactor = scaleToFit * 4.0

                        // Force immediate layout
                        pdfView.layoutDocumentView()
                        pdfView.setNeedsLayout()
                        pdfView.layoutIfNeeded()
                    }

                    // Return to the same page to avoid scrolling
                    if let page = currentPage {
                        pdfView.go(to: page)
                    }

                    // Update tracking after a brief delay to ensure changes stick
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        context.coordinator.lastSize = size
                        context.coordinator.lastPDFScaleFactor = pdfView.scaleFactor
                    }

                    // Lock zoom at new scale after everything settles
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if let scrollView = pdfView.subviews.first as? UIScrollView {
                            let currentZoom = scrollView.zoomScale
                            scrollView.maximumZoomScale = currentZoom
                            scrollView.minimumZoomScale = currentZoom
                            scrollView.bouncesZoom = false
                            context.coordinator.lastZoomScale = currentZoom
                        }
                    }
                } else {
                    // Ensure zoom stays locked even when size hasn't changed
                    if let scrollView = pdfView.subviews.first as? UIScrollView {
                        let currentZoom = scrollView.zoomScale
                        // Only reset if user has somehow zoomed
                        if abs(currentZoom - context.coordinator.lastZoomScale) > 0.01 {
                            scrollView.zoomScale = context.coordinator.lastZoomScale
                            scrollView.maximumZoomScale = context.coordinator.lastZoomScale
                            scrollView.minimumZoomScale = context.coordinator.lastZoomScale
                        }
                    }

                    // Also check PDF scale factor
                    if abs(pdfView.scaleFactor - context.coordinator.lastPDFScaleFactor) > 0.01 {
                        pdfView.scaleFactor = context.coordinator.lastPDFScaleFactor
                        pdfView.minScaleFactor = context.coordinator.lastPDFScaleFactor
                        pdfView.maxScaleFactor = context.coordinator.lastPDFScaleFactor * 4.0
                    }
                }
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        class Coordinator {
            var lastSize: CGSize = .zero
            var lastZoomScale: CGFloat = 1.0
            var lastPDFScaleFactor: CGFloat = 1.0
            var lastScrollOffset: CGPoint = .zero
        }

        // MARK: - Helper Methods

        private func updateScaleFactor(for pdfView: PDFView, width: CGFloat, resetPosition: Bool, context: Context) {
            guard let document = pdfView.document,
                  let page = document.page(at: 0) else { return }

            let pageSize = page.bounds(for: .mediaBox).size

            guard width > 0 else { return }

            let scaleToFit = width / pageSize.width

            // Only update if the scale has changed significantly (to avoid unnecessary updates)
            guard resetPosition || abs(pdfView.scaleFactor - scaleToFit) > 0.01 else { return }

            // Update scale factors
            pdfView.scaleFactor = scaleToFit
            pdfView.minScaleFactor = scaleToFit
            pdfView.maxScaleFactor = scaleToFit * 4.0

            // Force PDFView to update its layout with the new scale
            pdfView.layoutDocumentView()

            // Reset to first page on initial load
            if resetPosition {
                pdfView.go(to: page)
            }
        }
    }
}

#endif
#endif
