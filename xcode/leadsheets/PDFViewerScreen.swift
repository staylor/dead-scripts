import SwiftUI

struct PDFViewerScreen: View {
    let song: Song
    let onBack: () -> Void
    
    @State private var showInfo = false
    @State private var overlayPosition = CGPoint.zero
    
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
}

#if os(macOS)
// MARK: - macOS Lyrics Inspector
struct LyricsInspector: View {
    let song: Song
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Lyrics")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Divider()
                
                // Lyrics Content
                if let lyrics = song.lyrics, !lyrics.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(lyrics.components(separatedBy: "\n").enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.body)
                                .foregroundColor(.primary)
                                .fontWeight(line == "Chorus" || line == "Chorus - repeated" ? .bold : .regular)
                                .textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No lyrics available")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
    }
}
#endif
