import SwiftUI

#if os(iOS)
import PDFKit
import UIKit

extension PDFKitView {
    struct PDFKitViewRepresentable: UIViewRepresentable {
        let url: URL
        let barInsets: EdgeInsets

        func makeUIView(context: Context) -> SheetPDFView {
            let pdfView = SheetPDFView()
            pdfView.autoScales = false
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical
            // Dark behind the bars in dark mode, where they keep white titles; the page itself stays white.
            pdfView.backgroundColor = .systemBackground
            pdfView.pageShadowsEnabled = false
            pdfView.barInsets = barInsets
            pdfView.show(PDFDocument(url: url))
            return pdfView
        }

        func updateUIView(_ pdfView: SheetPDFView, context: Context) {
            if pdfView.barInsets != barInsets {
                pdfView.barInsets = barInsets
            }
            if pdfView.document?.documentURL != url {
                pdfView.show(PDFDocument(url: url))
            }
        }
    }
}

/// Fits the page to the view's width and insets it by the heights of the bars over it. Through layout changes,
/// such as a rotation, the lyrics or the sidebar opening, or the system laying the app out at other sizes for its
/// snapshots, it keeps the same part of the sheet at the top until the reader scrolls.
/// SwiftUI reports the bars' heights; on iOS 27 the scroll view's own safe area leaves out the navigation bar.
final class SheetPDFView: PDFView {
    var barInsets = EdgeInsets() {
        didSet {
            applyBarInsets()
        }
    }

    /// The fraction of the sheet's height at the top of the visible area, restored after each layout pass.
    private var heldPosition: CGFloat? = 0

    private var scrollView: UIScrollView? {
        subviews.first as? UIScrollView
    }

    /// PDFKit reads `document` from its own queues, so this sets it instead of an observer on the property.
    func show(_ document: PDFDocument?) {
        self.document = document
        heldPosition = 0
        setNeedsLayout()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        scrollView?.panGestureRecognizer.addTarget(self, action: #selector(readerScrolled))
    }

    override func layoutSubviews() {
        if let page = document?.page(at: 0), bounds.width > 0 {
            let scale = bounds.width / page.bounds(for: .mediaBox).width
            if abs(scaleFactor - scale) > scale / 1000 {
                // The scroll view still has its old layout here, so this is where the reader was.
                holdPosition()
                fit(scale)
            }
        }
        super.layoutSubviews()
        guard heldPosition != nil else { return }
        // The scroll view lays out after this view does, and PDFKit moves the page again in a later pass.
        DispatchQueue.main.async { [weak self] in
            self?.restoreHeldPosition()
        }
    }

    private func fit(_ scale: CGFloat) {
        // The zoom is locked at the last fitted scale, so release it before scaling.
        scrollView?.minimumZoomScale = 0.1
        scrollView?.maximumZoomScale = 10
        minScaleFactor = min(minScaleFactor, scale)
        maxScaleFactor = max(maxScaleFactor, scale)
        scaleFactor = scale
        minScaleFactor = scale
        maxScaleFactor = scale
        if let scrollView {
            scrollView.minimumZoomScale = scrollView.zoomScale
            scrollView.maximumZoomScale = scrollView.zoomScale
            scrollView.bouncesZoom = false
            scrollView.pinchGestureRecognizer?.isEnabled = false
        }
    }

    private func applyBarInsets() {
        guard let scrollView else { return }
        scrollView.contentInsetAdjustmentBehavior = .never
        let insets = UIEdgeInsets(top: barInsets.top, left: 0, bottom: barInsets.bottom, right: 0)
        guard scrollView.contentInset != insets else { return }
        holdPosition()
        scrollView.contentInset = insets
        scrollView.verticalScrollIndicatorInsets = insets
        setNeedsLayout()
    }

    private func holdPosition() {
        guard heldPosition == nil, let scrollView, scrollView.contentSize.height > 0 else { return }
        let position = (scrollView.contentOffset.y + scrollView.contentInset.top) / scrollView.contentSize.height
        heldPosition = min(max(position, 0), 1)
    }

    private func restoreHeldPosition() {
        guard let heldPosition, let scrollView else { return }
        let top = -scrollView.contentInset.top
        let bottom = max(top, scrollView.contentSize.height + scrollView.contentInset.bottom - scrollView.bounds.height)
        let offset = CGPoint(x: 0, y: min(max(heldPosition * scrollView.contentSize.height + top, top), bottom))
        if scrollView.contentOffset != offset {
            scrollView.setContentOffset(offset, animated: false)
        }
    }

    @objc private func readerScrolled() {
        heldPosition = nil
    }
}

#endif
