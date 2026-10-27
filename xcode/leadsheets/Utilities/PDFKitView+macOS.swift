import SwiftUI

#if os(macOS)
import PDFKit
import AppKit

extension PDFKitView {
    struct PDFKitViewRepresentable: NSViewRepresentable {
        let url: URL
        let size: CGSize
        @Binding var initialLoadComplete: Bool

        func makeNSView(context: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.autoScales = false
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical

            pdfView.backgroundColor = NSColor.white

            pdfView.layer?.shadowOpacity = 0
            pdfView.layer?.shadowRadius = 0
            pdfView.layer?.shadowOffset = CGSize.zero

            pdfView.pageShadowsEnabled = false

            if let document = PDFKit.PDFDocument(url: url) {
                pdfView.document = document

                // The view has no frame until it's laid out, so scale on the next pass.
                DispatchQueue.main.async {
                    self.updateScaleFactor(for: pdfView, width: size.width, resetPosition: true)
                    self.initialLoadComplete = true
                    context.coordinator.lastSize = size
                }
            }

            return pdfView
        }

        func updateNSView(_ pdfView: PDFView, context: Context) {
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
                let sizeChanged =
                    abs(context.coordinator.lastSize.width - size.width) > 1.0
                    || abs(context.coordinator.lastSize.height - size.height) > 1.0

                if sizeChanged {
                    pdfView.layoutDocumentView()
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

        private func updateScaleFactor(for pdfView: PDFView, width: CGFloat, resetPosition: Bool) {
            guard let document = pdfView.document,
                let page = document.page(at: 0)
            else { return }

            let pageSize = page.bounds(for: .mediaBox).size

            guard width > 0 else { return }

            let scaleToFit = width / pageSize.width

            guard resetPosition || abs(pdfView.scaleFactor - scaleToFit) > 0.01 else { return }

            pdfView.scaleFactor = scaleToFit
            pdfView.minScaleFactor = scaleToFit
            pdfView.maxScaleFactor = scaleToFit * 4.0

            pdfView.go(to: page)
        }
    }
}

#endif
