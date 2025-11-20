import SwiftUI

#if !os(watchOS)
/// A resize handle control that allows users to dynamically resize an overlay by dragging
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
                        #if os(iOS)
                        .fill(Color(.systemGray5))
                        #elseif os(tvOS)
                        .fill(Color.gray.opacity(0.3))
                        #else
                        .fill(Color(nsColor: .controlColor))
                        #endif
                        .opacity(isResizing ? 1.0 : 0.8)
                )
                .frame(width: 32, height: 32)
                .offset(x: geometry.size.width - 32, y: geometry.size.height - 32)
                #if os(iOS)
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
                #endif
        }
    }
}
#endif
