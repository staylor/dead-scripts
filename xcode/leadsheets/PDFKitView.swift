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
        GeometryReader { geometry in
            PDFKitViewRepresentable(
                url: url, 
                size: geometry.size, 
                initialLoadComplete: $initialLoadComplete,
                isReturningFromBackground: $isReturningFromBackground
            )
        }
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

#if os(iOS) || os(tvOS)
private struct PDFKitViewRepresentable: UIViewRepresentable {
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
            let sizeChanged = abs(context.coordinator.lastSize.width - size.width) > 1.0 ||
                             abs(context.coordinator.lastSize.height - size.height) > 1.0
            
            if sizeChanged {
                updateScaleFactor(for: pdfView, width: size.width, resetPosition: false, context: context)
                context.coordinator.lastSize = size
                
                // Update zoom lock after scale change
                DispatchQueue.main.async {
                    if let scrollView = pdfView.subviews.first as? UIScrollView {
                        let currentZoom = scrollView.zoomScale
                        scrollView.maximumZoomScale = currentZoom
                        scrollView.minimumZoomScale = currentZoom
                        context.coordinator.lastZoomScale = currentZoom
                        context.coordinator.lastScrollOffset = scrollView.contentOffset
                    }
                    context.coordinator.lastPDFScaleFactor = pdfView.scaleFactor
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
    @Binding var initialLoadComplete: Bool
    
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

#endif
