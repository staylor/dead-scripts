import SwiftUI

#if os(macOS)
import PDFKit
import AppKit

extension PDFKitView {
    struct PDFKitViewRepresentable: NSViewRepresentable {
        let url: URL

        func makeNSView(context: Context) -> SheetPDFView {
            let pdfView = SheetPDFView()
            pdfView.autoScales = false
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical
            pdfView.backgroundColor = .white
            pdfView.pageShadowsEnabled = false
            pdfView.show(PDFDocument(url: url))
            return pdfView
        }

        func updateNSView(_ pdfView: SheetPDFView, context: Context) {
            if pdfView.document?.documentURL != url {
                pdfView.show(PDFDocument(url: url))
            }
        }
    }
}

/// Fits the page to the view's width. When the view changes size, as the window resizes or the lyrics or the
/// sidebar open, it keeps the same part of the sheet at the top.
final class SheetPDFView: PDFView {
    private var fittedWidth: CGFloat = 0
    /// The part of the sheet at the top before the view changed size, restored once PDFKit has laid out the new size.
    private var positionBeforeResize: PDFDestination?
    /// Where the reader was when a live resize began. Each step returns there, so a step that runs into the end
    /// of the sheet doesn't move the reader for the rest of the resize.
    private var liveResizePosition: PDFDestination?

    func show(_ document: PDFDocument?) {
        self.document = document
        fittedWidth = 0
        positionBeforeResize = nil
        needsLayout = true
    }

    override func setFrameSize(_ newSize: NSSize) {
        if newSize != frame.size, fittedWidth > 0, positionBeforeResize == nil {
            positionBeforeResize = liveResizePosition ?? currentDestination
        }
        super.setFrameSize(newSize)
        needsLayout = true
    }

    override func layout() {
        super.layout()
        guard let page = document?.page(at: 0), bounds.width > 0 else { return }
        let isFirstFit = fittedWidth == 0
        if bounds.width != fittedWidth {
            let scale = bounds.width / page.bounds(for: .mediaBox).width
            minScaleFactor = min(minScaleFactor, scale)
            maxScaleFactor = max(maxScaleFactor, scale * 4)
            scaleFactor = scale
            minScaleFactor = scale
            maxScaleFactor = scale * 4
            fittedWidth = bounds.width
            layoutDocumentView()
        }
        if isFirstFit {
            go(to: page)
        } else if let position = positionBeforeResize {
            go(to: position)
            // Right after a resize PDFKit lands about 30 points off, so go there again once it has settled.
            Task { [weak self] in
                self?.go(to: position)
            }
        }
        positionBeforeResize = nil
    }

    override func viewWillStartLiveResize() {
        super.viewWillStartLiveResize()
        liveResizePosition = currentDestination
    }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        liveResizePosition = nil
    }
}

#endif
