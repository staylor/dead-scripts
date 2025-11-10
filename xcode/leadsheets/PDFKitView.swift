import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
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
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update if needed
    }
}