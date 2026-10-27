import SwiftUI

#if os(tvOS)
import DeadSheetsKit

struct ImageViewerScreen: View {
    let song: Song

    @FocusState private var focusedField: Field?
    @State private var zoomScale: CGFloat = 1.0
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollID = UUID()

    enum Field {
        case image
        case lyrics
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(song.title)
                        .font(.headline)
                    Text(song.creditsText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                GlassEffectContainer {
                    HStack(spacing: 40) {
                        Button("Scroll Up", systemImage: "arrow.up") {
                            scrollOffset = min(0, scrollOffset + 200)
                            scrollID = UUID()
                        }
                        Button("Scroll Down", systemImage: "arrow.down") {
                            scrollOffset -= 200
                            scrollID = UUID()
                        }
                        Button("Zoom Out", systemImage: "minus.magnifyingglass") {
                            zoomScale = max(1.0, zoomScale - 0.5)
                        }
                        Button("Zoom In", systemImage: "plus.magnifyingglass") {
                            zoomScale = min(3.0, zoomScale + 0.5)
                        }
                        Button("Reset") {
                            zoomScale = 1.0
                            scrollOffset = 0
                            scrollID = UUID()
                        }
                    }
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .buttonStyle(.glass)
                    .tint(.primary)
                }
            }
            .padding(.vertical, 40)

            HStack(spacing: 40) {
                if let imageURL = song.sheetImageURL,
                    let image = UIImage(contentsOfFile: imageURL.path(percentEncoded: false))
                {
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
                    ContentUnavailableView(
                        "Lead Sheet Missing",
                        systemImage: "doc.questionmark",
                        description: Text("“\(song.sheetFileName)” isn’t in this build.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .focusable(false)
                }

                let lyricsParagraphs = song.lyricParagraphs
                if !lyricsParagraphs.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Each paragraph is a button so the remote can move focus, and scroll, through the lyrics.
                            ForEach(lyricsParagraphs.indices, id: \.self) { index in
                                let paragraph = lyricsParagraphs[index]
                                Button(action: {}) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(paragraph.indices, id: \.self) { lineIndex in
                                            Text(paragraph[lineIndex])
                                                .font(.body)
                                                .lineSpacing(6)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .tint(.primary)
                                .focusable(true)
                                .focused($focusedField, equals: index == 0 ? .lyrics : nil)

                                if index < lyricsParagraphs.count - 1 {
                                    Color.clear
                                        .frame(height: 20)
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(width: 650)
                    .glassEffect(in: .rect(cornerRadius: 40))
                }
            }
        }
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .onAppear {
            focusedField = .image
        }
        .keepsScreenOn()
    }
}
#endif
