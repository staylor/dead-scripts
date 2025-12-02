import SwiftUI

#if os(tvOS)
struct ImageViewerScreen: View {
    let song: Song
    let onBack: () -> Void

    @FocusState private var focusedField: Field?
    @State private var zoomScale: CGFloat = 1.0
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollID = UUID()

    enum Field {
        case backButton
        case image
        case lyrics
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar with Back Button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.title3)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.card)
                .focused($focusedField, equals: .backButton)

                VStack(alignment: .leading, spacing: 8) {
                    Text(song.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(song.writersDisplayText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Scroll controls
                HStack(spacing: 40) {
                    Button(action: {
                        scrollOffset = min(0, scrollOffset + 200)
                        scrollID = UUID()
                    }) {
                        Image(systemName: "arrow.up")
                            .font(.title3)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.card)

                    Button(action: {
                        scrollOffset -= 200
                        scrollID = UUID()
                    }) {
                        Image(systemName: "arrow.down")
                            .font(.title3)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.card)

                    Button(action: {
                        zoomScale = max(1.0, zoomScale - 0.5)
                    }) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.title3)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.card)

                    Button(action: {
                        zoomScale = min(3.0, zoomScale + 0.5)
                    }) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.title3)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.card)

                    Button(action: {
                        zoomScale = 1.0
                        scrollOffset = 0
                        scrollID = UUID()
                    }) {
                        Text("Reset")
                            .font(.title3)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.card)
                }
            }
            .padding(.vertical, 40)
            .background(Color.black.opacity(0.3))
            .colorScheme(.dark)

            // Main Content: Image + Lyrics side-by-side
            HStack(spacing: 40) {
                // Left: Sheet Music Image (zoomable and pannable)
                if let imageURL = song.imageURL,
                   let image = NSUIImage(contentsOfFile: imageURL.path) {
                    GeometryReader { geometry in
                        let imageAspect = image.size.height / image.size.width
                        let imageHeight = geometry.size.width * imageAspect
                        let zoomedHeight = imageHeight * zoomScale
                        let maxOffset = min(0, -(zoomedHeight - geometry.size.height))

                        ScrollViewReader { proxy in
                            ScrollView([.horizontal, .vertical]) {
                                VStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: geometry.size.width)
                                        .scaleEffect(zoomScale, anchor: .center)
                                        .offset(y: max(maxOffset, scrollOffset))
                                }
                                .id("imageContent")
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .focusable(true)
                            .focused($focusedField, equals: .image)
                            .onChange(of: scrollID) { _, _ in
                                withAnimation {
                                    proxy.scrollTo("imageContent", anchor: .top)
                                }
                            }
                        }
                    }
                } else {
                    // Fallback if image not found
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text("Image not found")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .focusable(false)
                }

                // Right: Lyrics (if available)
                if let lyrics = song.lyrics, !lyrics.isEmpty {
                    let paragraphs = parseLyricsParagraphs(lyrics)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Group lyrics into paragraphs, each paragraph is focusable
                            ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                                Button(action: {}) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(Array(paragraph.enumerated()), id: \.offset) { _, line in
                                            Text(line)
                                                .font(.body)
                                                .lineSpacing(6)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .foregroundColor(.primary)
                                }
                                .buttonStyle(.plain)
                                .focusable(true)
                                .focused($focusedField, equals: index == 0 ? .lyrics : nil)

                                if index < paragraphs.count - 1 {
                                    Color.clear
                                        .frame(height: 20)
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(width: 650)
                    .background(Color.black.opacity(0.3))
                    .colorScheme(.dark)
                }
            }
        }
        .background(Color.black)
        .onAppear {
            // Set initial focus to back button
            focusedField = .backButton
        }
    }

    // Helper function to parse lyrics into paragraphs (separated by blank lines)
    private func parseLyricsParagraphs(_ lyrics: String) -> [[String]] {
        let lines = lyrics.components(separatedBy: "\n")
        var paragraphs: [[String]] = []
        var currentParagraph: [String] = []

        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                // Blank line - end current paragraph
                if !currentParagraph.isEmpty {
                    paragraphs.append(currentParagraph)
                    currentParagraph = []
                }
            } else {
                // Non-blank line - add to current paragraph
                currentParagraph.append(line)
            }
        }

        // Add last paragraph if not empty
        if !currentParagraph.isEmpty {
            paragraphs.append(currentParagraph)
        }

        return paragraphs
    }
}

// Type alias for UIKit/AppKit compatibility
#if canImport(UIKit)
typealias NSUIImage = UIImage
#elseif canImport(AppKit)
typealias NSUIImage = NSImage
#endif
#endif
