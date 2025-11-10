import SwiftUI

struct PDFViewerScreen: View {
    let song: Song
    let onBack: () -> Void
    
    @State private var showInfo = false
    @State private var overlayPosition = CGPoint.zero // Will be centered on first appearance
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen PDF View
                if let pdfURL = song.pdfURL {
                    PDFKitView(url: pdfURL)
                } else {
                    // Fallback if PDF not found
                    VStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text("PDF not found")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Overlay controls
                VStack {
                    HStack {
                        // Back Button
                        Button(action: onBack) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .glassEffect()
                        .scaleEffect(showInfo ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: showInfo)
                        .foregroundColor(.pink)
                        
                        Spacer()
                        
                        // Lyrics Button
                        Button(action: { showInfo.toggle() }) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 24))
                                .foregroundColor(.pink)
                                .padding(10)
                        }
                        .glassEffect()
                    }
                    .padding()
                    
                    Spacer()
                }
                
                // Lyrics Overlay
                if showInfo {
                    LyricsOverlay(song: song, isShowing: $showInfo, position: $overlayPosition, screenSize: geometry.size)
                        .position(overlayPosition == .zero ? CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2) : overlayPosition)
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            // Center the overlay on first appearance
                            if overlayPosition == .zero {
                                overlayPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            }
                        }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showInfo)
    }
}
