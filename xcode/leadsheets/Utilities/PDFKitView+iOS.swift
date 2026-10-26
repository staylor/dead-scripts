import SwiftUI

#if os(iOS)
import PDFKit
import UIKit

extension PDFKitView {
    struct PDFKitViewRepresentable: UIViewRepresentable {
        let url: URL
        let size: CGSize
        let barInsets: EdgeInsets
        @Binding var initialLoadComplete: Bool
        @Binding var isReturningFromBackground: Bool

        func makeUIView(context: Context) -> PDFView {
            let pdfView = SheetPDFView()
            pdfView.autoScales = false
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical
            pdfView.backgroundColor = UIColor.white
            pdfView.pageShadowsEnabled = false
            pdfView.barInsets = barInsets

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
            if let pdfView = pdfView as? SheetPDFView, pdfView.barInsets != barInsets {
                pdfView.barInsets = barInsets
            }

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

            if isReturningFromBackground {
                fitToWidth(pdfView: pdfView, width: size.width, scrollToTop: true)
                lockZoom(pdfView: pdfView)
                return
            }

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

        private func fitToWidth(pdfView: PDFView, width: CGFloat, scrollToTop: Bool = false) {
            guard let document = pdfView.document,
                let page = document.page(at: 0),
                width > 0
            else { return }

            // lockZoom pinned the zoom scale, so release it before changing the scale factor.
            if let scrollView = pdfView.subviews.first as? UIScrollView {
                scrollView.minimumZoomScale = 0.1
                scrollView.maximumZoomScale = 10.0
            }

            let pageWidth = page.bounds(for: .mediaBox).size.width
            let scale = width / pageWidth

            pdfView.scaleFactor = scale
            pdfView.minScaleFactor = scale
            pdfView.maxScaleFactor = scale

            if scrollToTop {
                pdfView.go(to: page)
                (pdfView as? SheetPDFView)?.pinToTop()
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

/// Insets the page by the heights of the bars over it, and keeps its top below them until the reader scrolls.
/// SwiftUI reports the bars' heights; on iOS 27 the scroll view's own safe area leaves out the navigation bar.
/// After `go(to:)`, the scroll view also puts the page back at the frame's top in its own layout pass.
final class SheetPDFView: PDFView {
    var barInsets = EdgeInsets() {
        didSet {
            applyBarInsets()
        }
    }

    private var isPinnedToTop = false

    private var scrollView: UIScrollView? {
        subviews.first as? UIScrollView
    }

    func pinToTop() {
        isPinnedToTop = true
        setNeedsLayout()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        scrollView?.panGestureRecognizer.addTarget(self, action: #selector(readerScrolled))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard isPinnedToTop else { return }
        // The scroll view lays out after this view does.
        DispatchQueue.main.async { [weak self] in
            self?.applyPin()
        }
    }

    private func applyBarInsets() {
        guard let scrollView else { return }
        let insets = UIEdgeInsets(top: barInsets.top, left: 0, bottom: barInsets.bottom, right: 0)
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = insets
        scrollView.verticalScrollIndicatorInsets = insets
        setNeedsLayout()
    }

    private func applyPin() {
        guard isPinnedToTop, let scrollView else { return }
        let top = CGPoint(x: 0, y: -scrollView.contentInset.top)
        if scrollView.contentOffset != top {
            scrollView.setContentOffset(top, animated: false)
        }
    }

    @objc private func readerScrolled() {
        isPinnedToTop = false
    }
}

#endif
