import SwiftUI

#if !os(watchOS) && !os(tvOS)
struct PDFViewerScreen: View {
    let song: Song
    let onBack: () -> Void
    
    @State private var showInfo = false
    @State private var overlayPosition = CGPoint.zero
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen PDF View
                if let pdfURL = song.pdfURL {
                    PDFKitView(url: pdfURL)
                        .id(pdfURL) // Keep PDF view stable across scene phase changes
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
                
                #if !os(macOS)
                // Overlay controls (iOS only)
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
                        
                        // Apple Music Button
                        if let appleMusicId = song.appleMusicId, !appleMusicId.isEmpty {
                            Button(action: {
                                openAppleMusic(songId: appleMusicId)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                        .font(.title2)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .glassEffect()
                            .foregroundColor(.pink)
                        }
                        
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
                
                // Lyrics Overlay (iOS only)
                if showInfo {
                    LyricsOverlay(song: song, isShowing: $showInfo, position: $overlayPosition, screenSize: geometry.size)
                        .position(overlayPosition == .zero ? CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2) : overlayPosition)
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            if overlayPosition == .zero {
                                overlayPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            }
                        }
                }
                #endif
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showInfo)
    }
    
    // MARK: - Helper Methods
    
    private func openAppleMusic(songId: String) {
        #if os(iOS)
        // Try to open in Apple Music app first
        if let url = URL(string: "music://music.apple.com/song/\(songId)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to web version
        if let url = URL(string: "https://music.apple.com/song/\(songId)") {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        // Try to open in Apple Music app
        if let url = URL(string: "music://music.apple.com/song/\(songId)") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}

#endif // !os(watchOS)
