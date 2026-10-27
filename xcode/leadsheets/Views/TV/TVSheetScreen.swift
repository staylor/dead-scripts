#if os(tvOS)
import DeadSheetsKit
import SwiftUI

/// A song's lead sheet beside its lyrics. Swiping scrolls whichever has focus, pressing zooms the sheet, and Back
/// zooms out before it leaves.
struct TVSheetScreen: View {
    let song: Song

    @State private var zoom = SheetZoom.fit
    @State private var viewport = SheetViewport()
    @State private var hint: SheetZoom? = .fit
    @State private var lastStanza = 0
    @State private var playbackFailure: PlaybackFailure?
    @FocusState private var focus: SheetFocus?

    private let player = MusicPlayerService.shared

    private var paragraphs: [[String]] {
        song.lyricParagraphs
    }

    var body: some View {
        HStack(alignment: .top, spacing: 48) {
            sheet
            if zoom == .fit {
                LyricsPanel(song: song, paragraphs: paragraphs, isPlaying: isPlaying, focus: $focus)
                    .frame(width: 640)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.smooth(duration: 0.4), value: zoom)
        // The tab bar is hidden, but its space stays in the safe area; keep only the 60-point overscan margin.
        .padding(.top, 60)
        .ignoresSafeArea(.container, edges: .top)
        .overlay(alignment: .bottom) {
            if let hint {
                Text(hintText(for: hint))
                    .font(.callout)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 18)
                    .glassEffect(in: .capsule)
                    .transition(.opacity)
            }
        }
        .animation(.smooth, value: hint)
        .background {
            Backdrop(song: song)
        }
        .environment(\.colorScheme, .dark)
        .toolbar(.hidden, for: .tabBar, .navigationBar)
        .defaultFocus($focus, .sheet)
        .onExitCommand(perform: zoom.previous.map { previous in { setZoom(previous) } })
        .onPlayPauseCommand(perform: togglePlayback)
        .alert(isPresented: isShowingFailure, error: playbackFailure) { _ in
            Button("OK", role: .cancel) {}
        } message: { failure in
            Text(failure.failureReason ?? "")
        }
        .onChange(of: focus) { _, focus in
            if case .stanza(let index) = focus {
                lastStanza = index
                hint = nil
            }
        }
        .task(id: hint) {
            guard hint != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            hint = nil
        }
        .keepsScreenOn()
    }

    @ViewBuilder
    private var sheet: some View {
        if let url = song.sheetURL {
            ZoomableSheet(url: url, zoom: zoom, viewport: viewport)
                .clipShape(.rect(cornerRadius: 24))
                .shadow(color: .black.opacity(0.5), radius: 30, y: 12)
                .opacity(focus == .sheet || focus == nil ? 1 : 0.5)
                .animation(.smooth(duration: 0.2), value: focus)
                .focusable()
                .focused($focus, equals: .sheet)
                .focusEffectDisabled()
                .onMoveCommand(perform: move)
                .onTapGesture {
                    setZoom(zoom.next)
                }
                .accessibilityLabel("Lead sheet")
                .accessibilityValue(zoom.name)
                .accessibilityHint(zoom.hint)
                .accessibilityIdentifier("sheet")
        } else {
            ContentUnavailableView(
                "Lead Sheet Missing",
                systemImage: "doc.questionmark",
                description: Text("“\(song.sheetFileName)” isn’t in this build.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(in: .rect(cornerRadius: 24))
        }
    }

    private func move(_ direction: MoveCommandDirection) {
        if zoom == .fit, direction == .right {
            if !paragraphs.isEmpty {
                focus = .stanza(min(lastStanza, paragraphs.count - 1))
            }
        } else {
            viewport.scroll(direction)
        }
    }

    private func hintText(for zoom: SheetZoom) -> String {
        zoom == .fit && song.appleMusicID != nil ? "\(zoom.hint)  ·  Play/Pause plays the song" : zoom.hint
    }

    private var isPlaying: Bool {
        song.appleMusicID.map(player.isPlayingSong) ?? false
    }

    private var isShowingFailure: Binding<Bool> {
        Binding(
            get: { playbackFailure != nil },
            set: { if !$0 { playbackFailure = nil } }
        )
    }

    /// tvOS has no subscription offer, so someone without Apple Music is told they need it.
    private func togglePlayback() {
        guard let appleMusicID = song.appleMusicID else { return }
        if isPlaying {
            player.pause()
            return
        }
        Task {
            switch await player.start(appleMusicID: appleMusicID, title: song.title) {
            case .playing:
                break
            case .needsSubscription:
                playbackFailure = PlaybackFailure(songTitle: song.title, appleMusicID: appleMusicID, reason: .noSubscription)
            case .failed(let failure):
                playbackFailure = failure
            }
        }
    }

    private func setZoom(_ newZoom: SheetZoom) {
        zoom = newZoom
        hint = newZoom
    }
}

private enum SheetFocus: Hashable {
    case sheet
    case stanza(Int)
}

extension SheetZoom {
    fileprivate var name: String {
        switch self {
        case .fit: "Beside the lyrics"
        case .fill: "Full width"
        case .close: "Zoomed in"
        }
    }

    fileprivate var hint: String {
        switch self {
        case .fit: "Swipe to scroll  ·  Press to zoom"
        case .fill: "Press to zoom in  ·  Back for the lyrics"
        case .close: "Swipe to look around  ·  Press to see the whole page"
        }
    }
}

/// The lyrics, a stanza at a time: moving through them scrolls the panel, and the one in focus stands out.
private struct LyricsPanel: View {
    let song: Song
    let paragraphs: [[String]]
    let isPlaying: Bool
    let focus: FocusState<SheetFocus?>.Binding

    var body: some View {
        let isReading = if case .stanza = focus.wrappedValue { true } else { false }
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(song.title)
                        .font(.title3)
                        .bold()
                    Group {
                        Text(song.creditsText)
                        if let singer = song.singer {
                            Text("Sung by \(singer.name)")
                        }
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    if isPlaying {
                        Label("Playing in Apple Music", systemImage: "speaker.wave.2.fill")
                            .symbolEffect(.variableColor.iterative)
                            .font(.callout)
                            .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                if paragraphs.isEmpty {
                    Text("No lyrics")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                }
                ForEach(paragraphs.indices, id: \.self) { index in
                    let isFocused = focus.wrappedValue == .stanza(index)
                    Stanza(lines: paragraphs[index], isFocused: isFocused)
                        .opacity(isReading && !isFocused ? 0.45 : 1)
                        .focusable()
                        .focused(focus, equals: .stanza(index))
                        .focusEffectDisabled()
                        .accessibilityIdentifier("stanza-\(index)")
                }
            }
            .padding(.vertical, 36)
            .padding(.horizontal, 16)
        }
        .clipShape(.rect(cornerRadius: 40))
        .glassEffect(in: .rect(cornerRadius: 40))
        .opacity(focus.wrappedValue == .sheet ? 0.75 : 1)
        .animation(.smooth(duration: 0.2), value: focus.wrappedValue)
    }
}

private struct Stanza: View {
    let lines: [String]
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(lines.indices, id: \.self) { index in
                Text(lines[index])
                    .bold(Song.isChorusHeading(lines[index]))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.white.opacity(isFocused ? 0.16 : 0), in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
}

/// The album's cover, blurred, so the glass has some color to pick up.
private struct Backdrop: View {
    let song: Song

    var body: some View {
        ZStack {
            Color.black
            if let fileName = song.coverFileName, let image = ImageLoader.loadImage(named: fileName) {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 80)
                    .opacity(0.55)
            }
        }
        .ignoresSafeArea()
    }
}
#endif
