import SwiftUI

#if !os(watchOS) && !os(tvOS)
struct PDFViewerScreen: View {
    let song: Song
    let onBack: () -> Void

    @State private var showInfo = false
    @State private var overlayPosition = CGPoint.zero
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var musicPlayer = MusicPlayerService.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen PDF View
                if let pdfURL = song.pdfURL {
                    PDFKitView(url: pdfURL)
                        .id(pdfURL) // Keep PDF view stable across scene phase changes
                        #if os(iOS)
                        .padding(.top, UIDevice.current.userInterfaceIdiom == .phone ? 40 : 0)
                        #endif
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
                            let isThisSongPlaying = musicPlayer.isPlayingSong(appleMusicId)
                            let isThisSongLoading = musicPlayer.isLoadingSong(appleMusicId)
                            Button(action: {
                                if isThisSongPlaying {
                                    musicPlayer.pause()
                                } else {
                                    Task {
                                        await musicPlayer.play(appleMusicId: appleMusicId, songName: song.name)
                                    }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    if isThisSongLoading {
                                        ProgressView()
                                            .tint(.pink)
                                    } else {
                                        Image(systemName: isThisSongPlaying ? "pause.fill" : "play.fill")
                                            .font(.title2)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .disabled(isThisSongLoading)
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
    
}

#endif // !os(watchOS)
