import SwiftUI

#if !os(watchOS)
import PDFKit

#if canImport(UIKit)
import UIKit
#endif

struct PDFKitView: View {
    let url: URL
    
    var body: some View {
        GeometryReader { geometry in
            PDFKitViewRepresentable(url: url, size: geometry.size)
        }
    }
}

#if os(iOS) || os(tvOS)
private struct PDFKitViewRepresentable: UIViewRepresentable {
    let url: URL
    let size: CGSize
    
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
                self.updateScaleFactor(for: pdfView, width: size.width, resetPosition: true)
            }
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Check if we need to load a different PDF
        if pdfView.document?.documentURL != url {
            if let document = PDFKit.PDFDocument(url: url) {
                pdfView.document = document
                DispatchQueue.main.async {
                    self.updateScaleFactor(for: pdfView, width: size.width, resetPosition: true)
                }
            }
        } else {
            // Use the size from GeometryReader instead of pdfView.bounds
            updateScaleFactor(for: pdfView, width: size.width, resetPosition: false)
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateScaleFactor(for pdfView: PDFView, width: CGFloat, resetPosition: Bool) {
        guard let document = pdfView.document,
              let page = document.page(at: 0) else { return }
        
        let pageSize = page.bounds(for: .mediaBox).size
        
        guard width > 0 else { return }
        
        let scaleToFit = width / pageSize.width
        
        // Only update if the scale has changed significantly (to avoid unnecessary updates)
        guard resetPosition || abs(pdfView.minScaleFactor - scaleToFit) > 0.01 else { return }
        
        // Store current scroll position before changing scale (only during resize)
        var relativeScrollY: CGFloat = 0
        
        if !resetPosition, let currentPage = pdfView.currentPage {
            // Get the document view (scroll view) to calculate relative position
            if pdfView.documentView != nil {
                let scrollView = pdfView.subviews.first as? UIScrollView
                let currentOffset = scrollView?.contentOffset.y ?? 0
                let maxOffset = (scrollView?.contentSize.height ?? 1) - (scrollView?.bounds.height ?? 0)
                relativeScrollY = maxOffset > 0 ? currentOffset / maxOffset : 0
            }
        }
        
        // Update scale factors
        pdfView.scaleFactor = scaleToFit
        pdfView.minScaleFactor = scaleToFit
        pdfView.maxScaleFactor = scaleToFit * 4.0
        
        // Restore scroll position
        if resetPosition {
            // Go to the first page and scroll to top on initial load
            pdfView.go(to: page)
        } else {
            // Maintain relative scroll position during resize
            DispatchQueue.main.async {
                if let scrollView = pdfView.subviews.first as? UIScrollView {
                    let maxOffset = scrollView.contentSize.height - scrollView.bounds.height
                    let newOffset = relativeScrollY * maxOffset
                    scrollView.contentOffset.y = max(0, min(newOffset, maxOffset))
                }
            }
        }
    }
}
#elseif os(macOS)
private struct PDFKitViewRepresentable: NSViewRepresentable {
    let url: URL
    let size: CGSize
    
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
                }
            }
        } else {
            updateScaleFactor(for: pdfView, width: size.width, resetPosition: false)
        }
    }
    
    private func updateScaleFactor(for pdfView: PDFView, width: CGFloat, resetPosition: Bool) {
        guard let document = pdfView.document,
              let page = document.page(at: 0) else { return }
        
        let pageSize = page.bounds(for: .mediaBox).size
        
        guard width > 0 else { return }
        
        let scaleToFit = width / pageSize.width
        
        guard resetPosition || abs(pdfView.minScaleFactor - scaleToFit) > 0.01 else { return }
        
        pdfView.scaleFactor = scaleToFit
        pdfView.minScaleFactor = scaleToFit
        pdfView.maxScaleFactor = scaleToFit * 4.0
        
        if resetPosition, let page = document.page(at: 0) {
            pdfView.go(to: page)
        }
    }
}
#endif

#endif // !os(watchOS)
