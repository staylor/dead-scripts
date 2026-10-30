#if os(iOS) || os(macOS)
import DeadSheetsKit
import SwiftUI

/// A song's lead sheet, with playback and its lyrics.
struct SheetView: View {
    let song: Song
    var navigation = SongNavigation(previous: nil, next: nil)
    /// The split view's sidebar, which the lyrics push aside in landscape on a large iPhone.
    var sidebarVisibility: Binding<NavigationSplitViewVisibility> = .constant(.automatic)

    #if os(macOS)
    @AppStorage("showsLyrics") private var showsLyrics = true
    #else
    @State private var showsLyrics = false
    @State private var shownLyricsPlacement = LyricsPlacement.sheet
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @AppStorage(SettingsKey.keepsScreenOn) private var keepsScreenOn = true

    var body: some View {
        HStack(spacing: 0) {
            sheet
            #if os(iOS)
            if showsLyrics, lyricsPlacement == .beside {
                LyricsView(song: song)
                    .frame(width: Self.lyricsWidth)
                    .background(Color(uiColor: .secondarySystemBackground))
            }
            #endif
        }
        .navigationTitle(song.title)
        .navigationSubtitle(subtitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            if verticalSizeClass == .compact {
                // In landscape a bottom bar takes a fifth of the height, and beside a sidebar it doesn't appear.
                ToolbarItemGroup(placement: .topBarLeading) {
                    previousButton
                    nextButton
                }
                ToolbarSpacer(.fixed, placement: .primaryAction)
                ToolbarItemGroup(placement: .primaryAction) {
                    FavoriteButton(songID: song.id)
                    AddToSetlistMenu(songID: song.id)
                }
            } else {
                ToolbarItemGroup(placement: .bottomBar) {
                    previousButton
                    Spacer()
                    FavoriteButton(songID: song.id)
                    AddToSetlistMenu(songID: song.id)
                    Spacer()
                    nextButton
                }
            }
            #else
            ToolbarItemGroup(placement: .navigation) {
                previousButton
                nextButton
            }
            ToolbarItemGroup {
                FavoriteButton(songID: song.id)
                AddToSetlistMenu(songID: song.id)
            }
            #endif
            if let appleMusicID = song.appleMusicID {
                ToolbarItem {
                    PlayButton(appleMusicID: appleMusicID, title: song.title)
                }
            }
            ToolbarItem {
                Toggle(isOn: $showsLyrics) {
                    Label("Lyrics", systemImage: "text.quote")
                }
            }
        }
        .focusedSceneValue(\.shownSong, song)
        .focusedSceneValue(\.showsLyrics, $showsLyrics)
        .focusedSceneValue(\.songNavigation, navigation)
        .pageTurnerKeys(navigation)
        .keepsScreenOn(keepsScreenOn)
        .userActivity(SongActivity.type) { activity in
            activity.title = "\(song.title) — \(song.artistName)"
            activity.userInfo = [SongActivity.songIDKey: song.id]
            activity.isEligibleForHandoff = true
        }
        .inspector(isPresented: inspectorIsPresented) {
            LyricsView(song: song)
                .inspectorColumnWidth(min: 240, ideal: Self.lyricsWidth, max: 420)
        }
        #if os(iOS)
        .sheet(isPresented: showsLyrics(in: .sheet)) {
            lyricsSheet
        }
        .onChange(of: lyricsPlacement, initial: true) { _, placement in
            shownLyricsPlacement = placement
        }
        .onChange(of: lyricsNeedTheSidebarsRoom, initial: true) { _, needRoom in
            guard needRoom else { return }
            // Turning to landscape, the split view sets its own column visibility as it expands, after this runs.
            Task {
                sidebarVisibility.wrappedValue = .detailOnly
            }
        }
        #else
        // A minimum width on the sheet counts the sidebar twice, which kept the window at least 1,645 points wide.
        // The column's minimum counts it once, and includes the lyrics.
        .navigationSplitViewColumnWidth(min: columnWidth, ideal: columnWidth)
        #endif
    }

    private static let lyricsWidth: CGFloat = 320

    #if os(macOS)
    /// The narrowest the sheet gets, with room for the lyrics beside it.
    private var columnWidth: CGFloat {
        showsLyrics ? 480 + Self.lyricsWidth : 480
    }
    #endif

    private var inspectorIsPresented: Binding<Bool> {
        #if os(iOS)
        showsLyrics(in: .inspector)
        #else
        $showsLyrics
        #endif
    }

    #if os(iOS)
    private enum LyricsPlacement {
        case inspector, sheet, beside
    }

    /// An inspector column on iPad, a sheet under the music on iPhone, and beside the music when an iPhone is
    /// in landscape, where a sheet would cover it. Each placement has one presentation style: an inspector that
    /// changes between a sheet and a column as the device turns closes on iOS 26 and stays open on iOS 27.
    private var lyricsPlacement: LyricsPlacement {
        if verticalSizeClass == .compact {
            .beside
        } else if horizontalSizeClass == .compact {
            .sheet
        } else {
            .inspector
        }
    }

    private var lyricsSheet: some View {
        LyricsView(song: song)
            .presentationDetents([.medium, .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }

    /// A large iPhone in landscape shows the sidebar, and the lyrics beside the sheet need its room.
    private var lyricsNeedTheSidebarsRoom: Bool {
        showsLyrics && lyricsPlacement == .beside && horizontalSizeClass == .regular
    }

    /// Whether the lyrics are open in `placement`. A presentation that ends because the device turned and the
    /// lyrics moved doesn't close them.
    private func showsLyrics(in placement: LyricsPlacement) -> Binding<Bool> {
        Binding(
            get: { showsLyrics && lyricsPlacement == placement },
            set: { isPresented in
                guard placement == .sheet, !isPresented else {
                    showsLyrics = isPresented
                    return
                }
                // As an iPhone turns, the system can end the sheet before this view sees the new size class.
                Task {
                    if shownLyricsPlacement == .sheet {
                        showsLyrics = false
                    }
                }
            }
        )
    }
    #endif

    private var previousButton: some View {
        Button("Previous Song", systemImage: "chevron.backward") {
            navigation.previous?()
        }
        .disabled(navigation.previous == nil)
    }

    private var nextButton: some View {
        Button("Next Song", systemImage: "chevron.forward") {
            navigation.next?()
        }
        .disabled(navigation.next == nil)
    }

    @ViewBuilder
    private var sheet: some View {
        if let url = song.sheetURL {
            PDFKitView(url: url)
        } else {
            ContentUnavailableView(
                "Lead Sheet Missing",
                systemImage: "doc.questionmark",
                description: Text("“\(song.sheetFileName)” isn’t in this build.")
            )
        }
    }

    private var subtitle: String {
        var subtitle = song.artistAndAlbum
        if let year = song.albumReleaseYear {
            subtitle += " (\(year))"
        }
        #if os(macOS)
        subtitle += " · \(song.creditsText)"
        #endif
        return subtitle
    }
}

#Preview {
    if let song = Catalog.bundled.songs.first {
        NavigationStack {
            SheetView(song: song)
        }
    }
}
#endif
