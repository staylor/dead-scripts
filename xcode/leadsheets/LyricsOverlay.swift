import SwiftUI

struct LyricsOverlay: View {
    let song: Song
    @Binding var isShowing: Bool
    @Binding var position: CGPoint
    let screenSize: CGSize
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var overlaySize = CGSize(width: 350, height: 500)
    @State private var isResizing = false
    
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
                    
                    if let artist = song.artist {
                        Text(artist.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let album = song.album {
                        Text(album.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    if let lyrics = song.lyrics, !lyrics.isEmpty {
                        Text(lyrics)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(4)
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
    }
}

// MARK: - Resize Handle
struct ResizeHandle: View {
    @Binding var size: CGSize
    @Binding var isResizing: Bool
    let screenSize: CGSize
    let position: CGPoint
    
    @State private var initialSize = CGSize.zero
    
    // Size constraints
    private let minWidth: CGFloat = 250
    private let minHeight: CGFloat = 200
    private let maxWidth: CGFloat = 600  // Maximum width
    private let maxHeight: CGFloat = 800 // Maximum height
    
    // Determine which corner to place the handle based on horizontal position
    private var handleCorner: Corner {
        let isRight = position.x > screenSize.width * 0.6
        return isRight ? .bottomLeft : .bottomRight
    }
    
    private enum Corner {
        case bottomLeft, bottomRight
        
        var icon: String {
            switch self {
            case .bottomLeft:
                return "arrow.up.forward.and.arrow.down.backward"
            case .bottomRight:
                return "arrow.up.backward.and.arrow.down.forward"
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            Image(systemName: handleCorner.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color(.systemGray5))
                        .opacity(isResizing ? 1.0 : 0.8)
                )
                .frame(width: 32, height: 32)
                .offset(handleOffset(geometry: geometry))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isResizing {
                                // Store the initial size when dragging starts
                                initialSize = size
                                isResizing = true
                            }
                            
                            // Calculate size delta based on which corner we're dragging
                            let (widthDelta, heightDelta) = getSizeDelta(translation: value.translation)
                            
                            // Calculate new size based on initial size + drag translation
                            let newWidth = initialSize.width + widthDelta
                            let newHeight = initialSize.height + heightDelta
                            
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
    
    // Calculate the offset for the handle based on which corner it should be in
    private func handleOffset(geometry: GeometryProxy) -> CGSize {
        switch handleCorner {
        case .bottomRight:
            return CGSize(width: geometry.size.width - 32, height: geometry.size.height - 32)
        case .bottomLeft:
            return CGSize(width: 0, height: geometry.size.height - 32)
        }
    }
    
    // Calculate the size delta based on which corner we're resizing from
    private func getSizeDelta(translation: CGSize) -> (width: CGFloat, height: CGFloat) {
        switch handleCorner {
        case .bottomRight:
            // Drag right = bigger, drag down = bigger
            return (translation.width, translation.height)
        case .bottomLeft:
            // Drag left = bigger (negative), drag down = bigger
            return (-translation.width, translation.height)
        }
    }
}