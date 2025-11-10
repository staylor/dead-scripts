import SwiftUI

struct LyricsOverlay: View {
    let song: Song
    @Binding var isShowing: Bool
    @Binding var position: CGPoint
    let screenSize: CGSize
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var overlaySize = CGSize.zero // Will be set in onAppear
    @State private var isResizing = false
    
    // Adaptive initial size based on screen
    private var defaultOverlaySize: CGSize {
        let width = min(450, screenSize.width * 0.85)
        let height = min(600, screenSize.height * 0.7)
        return CGSize(width: width, height: height)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Draggable Header
            HStack {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.gray)
                    .font(.caption)
                
                Text("Lyrics")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { isShowing = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemGray5))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isResizing {
                            isDragging = true
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if !isResizing {
                            isDragging = false
                            let newX = position.x + value.translation.width
                            let newY = position.y + value.translation.height
                            
                            // Keep overlay within screen bounds (with some padding)
                            let minX: CGFloat = overlaySize.width / 2
                            let maxX: CGFloat = screenSize.width - overlaySize.width / 2
                            let minY: CGFloat = overlaySize.height / 2
                            let maxY: CGFloat = screenSize.height - overlaySize.height / 2
                            
                            position.x = max(minX, min(maxX, newX))
                            position.y = max(minY, min(maxY, newY))
                            dragOffset = CGSize.zero
                        }
                    }
            )
            
            Divider()
            
            // Lyrics Content
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(song.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        if let artist = song.artist {
                            Text(artist.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let album = song.album {
                            Text("•")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(album.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)
                    
                    if let lyrics = song.lyrics, !lyrics.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(lyrics.components(separatedBy: "\n").enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .bold(line == "Chorus" || line == "Chorus - repeated")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("No lyrics available")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .frame(width: overlaySize.width, height: overlaySize.height)
        .background(Color(.systemBackground).opacity(isDragging || isResizing ? 0.9 : 0.95))
        .cornerRadius(16)
        .shadow(color: .black.opacity(isDragging || isResizing ? 0.2 : 0.1), radius: isDragging || isResizing ? 15 : 10, x: 0, y: isDragging || isResizing ? 8 : 4)
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .offset(dragOffset)
        .overlay(
            // Resize handle - position adapts based on screen location
            ResizeHandle(
                size: $overlaySize,
                isResizing: $isResizing,
                screenSize: screenSize,
                position: position
            )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: overlaySize)
        .onAppear {
            // Set initial size based on screen size
            if overlaySize == .zero {
                overlaySize = defaultOverlaySize
            }
        }
        .onChange(of: screenSize) { oldSize, newSize in
            // Adjust overlay size and position when screen size changes
            adjustForScreenResize(oldSize: oldSize, newSize: newSize)
        }
        .onChange(of: overlaySize) { oldSize, newSize in
            // When overlay size changes, ensure position is still valid
            ensurePositionWithinBounds()
        }
    }
    
    // MARK: - Helper Methods
    
    private func adjustForScreenResize(oldSize: CGSize, newSize: CGSize) {
        // Calculate new constraints based on new screen size
        let maxWidth = min(600, newSize.width * 0.95)
        let maxHeight = min(800, newSize.height * 0.9)
        let minWidth = min(250, newSize.width * 0.6)
        let minHeight = min(200, newSize.height * 0.3)
        
        // When screen gets smaller, aggressively shrink overlay if needed
        if newSize.width < oldSize.width || newSize.height < oldSize.height {
            // Shrink to fit within new bounds
            overlaySize.width = min(overlaySize.width, maxWidth)
            overlaySize.height = min(overlaySize.height, maxHeight)
            
            // Ensure we meet minimum size
            overlaySize.width = max(minWidth, overlaySize.width)
            overlaySize.height = max(minHeight, overlaySize.height)
        } else {
            // Screen is getting larger, just enforce constraints
            overlaySize.width = max(minWidth, min(maxWidth, overlaySize.width))
            overlaySize.height = max(minHeight, min(maxHeight, overlaySize.height))
        }
        
        // Position will be adjusted by the onChange(overlaySize) handler
    }
    
    private func ensurePositionWithinBounds() {
        // Adjust position to keep overlay fully within screen bounds
        // Add a small padding to ensure it doesn't touch edges
        let padding: CGFloat = 10
        let minX: CGFloat = overlaySize.width / 2 + padding
        let maxX: CGFloat = screenSize.width - overlaySize.width / 2 - padding
        let minY: CGFloat = overlaySize.height / 2 + padding
        let maxY: CGFloat = screenSize.height - overlaySize.height / 2 - padding
        
        position.x = max(minX, min(maxX, position.x))
        position.y = max(minY, min(maxY, position.y))
    }
}

// MARK: - Resize Handle
struct ResizeHandle: View {
    @Binding var size: CGSize
    @Binding var isResizing: Bool
    let screenSize: CGSize
    let position: CGPoint
    
    @State private var initialSize = CGSize.zero
    
    // Size constraints - adaptive to screen size
    private var minWidth: CGFloat { 
        min(250, screenSize.width * 0.6) 
    }
    private var minHeight: CGFloat { 
        min(200, screenSize.height * 0.3) 
    }
    private var maxWidth: CGFloat { 
        min(600, screenSize.width * 0.95) 
    }
    private var maxHeight: CGFloat { 
        min(800, screenSize.height * 0.9) 
    }
    
    var body: some View {
        GeometryReader { geometry in
            Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color(.systemGray5))
                        .opacity(isResizing ? 1.0 : 0.8)
                )
                .frame(width: 32, height: 32)
                .offset(x: geometry.size.width - 32, y: geometry.size.height - 32)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isResizing {
                                // Store the initial size when dragging starts
                                initialSize = size
                                isResizing = true
                            }
                            
                            // Calculate new size based on initial size + drag translation
                            // Drag right = bigger width, drag down = bigger height
                            let newWidth = initialSize.width + value.translation.width
                            let newHeight = initialSize.height + value.translation.height
                            
                            // Apply constraints
                            let constrainedWidth = max(minWidth, min(min(maxWidth, screenSize.width * 0.9), newWidth))
                            let constrainedHeight = max(minHeight, min(min(maxHeight, screenSize.height * 0.9), newHeight))
                            
                            size = CGSize(width: constrainedWidth, height: constrainedHeight)
                        }
                        .onEnded { _ in
                            isResizing = false
                            initialSize = .zero
                        }
                )
        }
    }
}
