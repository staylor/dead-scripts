import SwiftUI

#if os(iOS)
import PDFKit
import UIKit

extension PDFKitView {
    struct PDFKitViewRepresentable: UIViewRepresentable {
        let url: URL
        let size: CGSize
        @Binding var initialLoadComplete: Bool
        @Binding var isReturningFromBackground: Bool

        func makeUIView(context: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.autoScales = false
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical
            pdfView.backgroundColor = UIColor.white
            pdfView.pageShadowsEnabled = false

            if let document = PDFDocument(url: url) {
                pdfView.document = document
                DispatchQueue.main.async {
                    self.fitToWidth(pdfView: pdfView, width: size.width, scrollToTop: true)
                    self.lockZoom(pdfView: pdfView)
                    self.initialLoadComplete = true
                    context.coordinator.lastWidth = size.width
                }
            }

            return pdfView
        }

        func updateUIView(_ pdfView: PDFView, context: Context) {
            // Load different PDF if URL changed
            if pdfView.document?.documentURL != url {
                if let document = PDFDocument(url: url) {
                    pdfView.document = document
                    DispatchQueue.main.async {
                        self.fitToWidth(pdfView: pdfView, width: size.width, scrollToTop: true)
                        self.lockZoom(pdfView: pdfView)
                        self.initialLoadComplete = true
                        context.coordinator.lastWidth = size.width
                    }
                }
                return
            }

            // Handle returning from background
            if isReturningFromBackground {
                fitToWidth(pdfView: pdfView, width: size.width, scrollToTop: true)
                lockZoom(pdfView: pdfView)
                return
            }

            // Handle width change (orientation change)
            let widthChanged = abs(context.coordinator.lastWidth - size.width) > 1.0
            if widthChanged && initialLoadComplete {
                fitToWidth(pdfView: pdfView, width: size.width, scrollToTop: true)
                lockZoom(pdfView: pdfView)
                context.coordinator.lastWidth = size.width
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        class Coordinator {
            var lastWidth: CGFloat = 0
        }

        // MARK: - Helper Methods

        private func fitToWidth(pdfView: PDFView, width: CGFloat, scrollToTop: Bool = false) {
            guard let document = pdfView.document,
                  let page = document.page(at: 0),
                  width > 0 else { return }

            // Unlock zoom first to allow scale change
            if let scrollView = pdfView.subviews.first as? UIScrollView {
                scrollView.minimumZoomScale = 0.1
                scrollView.maximumZoomScale = 10.0
            }

            let pageWidth = page.bounds(for: .mediaBox).size.width
            let scale = width / pageWidth

            pdfView.scaleFactor = scale
            pdfView.minScaleFactor = scale
            pdfView.maxScaleFactor = scale

            // Scroll to top of first page only on initial load
            if scrollToTop {
                pdfView.go(to: page)
                if let scrollView = pdfView.subviews.first as? UIScrollView {
                    scrollView.setContentOffset(.zero, animated: false)
                }
            }
        }

        private func lockZoom(pdfView: PDFView) {
            guard let scrollView = pdfView.subviews.first as? UIScrollView else { return }
            scrollView.minimumZoomScale = scrollView.zoomScale
            scrollView.maximumZoomScale = scrollView.zoomScale
            scrollView.bouncesZoom = false
            scrollView.pinchGestureRecognizer?.isEnabled = false
        }
    }
}

#endif
