#if os(tvOS)
import DeadSheetsKit
import SwiftUI

/// Album covers in rows, as tvOS shows albums.
struct TVAlbumGrid: View {
    @Environment(\.catalog) private var catalog

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Self.columns(5), spacing: 64) {
                ForEach(catalog.albums(matching: "")) { album in
                    NavigationLink(value: LibraryRoute.album(album)) {
                        Lockup(title: album.title, subtitle: LibraryRoute.album(album).summary(in: catalog)) {
                            TVArtwork(appleMusicID: album.appleMusicID, placeholder: "square.stack")
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .buttonStyle(.borderless)
                    .accessibilityIdentifier("album-\(album.id)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
    }

    static func columns(_ count: Int) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 48, alignment: .top), count: count)
    }
}

/// Artists, singers or writers, as round photos.
struct TVPeopleGrid: View {
    let category: LibraryCategory

    @Environment(\.catalog) private var catalog

    var body: some View {
        ScrollView {
            LazyVGrid(columns: TVAlbumGrid.columns(6), spacing: 64) {
                ForEach(routes, id: \.self) { route in
                    NavigationLink(value: route) {
                        PortraitLockup(route: route, summary: route.summary(in: catalog))
                    }
                    .buttonStyle(PortraitButtonStyle())
                    .accessibilityIdentifier(route.identifier)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
    }

    private var routes: [LibraryRoute] {
        switch category {
        case .artists: catalog.artists(matching: "").map(LibraryRoute.artist)
        case .singers: catalog.singers(matching: "").map(LibraryRoute.singer)
        case .writers: catalog.writerGroups().map(LibraryRoute.writers)
        case .songs, .albums, .covers, .setlists: []
        }
    }
}

/// Artwork with its title and details below; the borderless style lifts the artwork when it's in focus.
private struct Lockup<Artwork: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let artwork: Artwork

    var body: some View {
        VStack(spacing: 16) {
            artwork
            LockupText(title: title, subtitle: subtitle)
        }
    }
}

/// A round photo and its name. The borderless style lifts the square image inside the circle, where it doesn't
/// show, so this lifts the circle itself.
private struct PortraitLockup: View {
    let route: LibraryRoute
    let summary: String

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        VStack(spacing: 16) {
            TVArtwork(appleMusicID: route.appleMusicID, placeholder: route.placeholder)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.circle)
                .scaleEffect(isFocused ? 1.12 : 1)
                .shadow(color: .black.opacity(isFocused ? 0.5 : 0), radius: 20, y: 14)
            LockupText(title: route.title, subtitle: summary)
                .offset(y: isFocused ? 14 : 0)
        }
        .animation(.smooth(duration: 0.2), value: isFocused)
    }
}

private struct PortraitButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

private struct LockupText: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.callout)
                .lineLimit(2)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .multilineTextAlignment(.center)
    }
}

/// A cover or photo from Apple Music that fills its frame, with the placeholder symbol when there's none. It's an
/// `Image`, which the borderless button style lifts when the lockup has focus.
struct TVArtwork: View {
    let appleMusicID: String?
    let placeholder: String?

    var body: some View {
        let store = ArtworkStore.shared
        Group {
            if let image = store.image(for: appleMusicID, width: Self.pixels, height: Self.pixels) {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFill()
            } else if let placeholder {
                Image(systemName: placeholder)
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.fill.tertiary)
            } else {
                Color.clear
            }
        }
        .task(id: store.url(for: appleMusicID, width: Self.pixels, height: Self.pixels)) {
            await store.download(appleMusicID, width: Self.pixels, height: Self.pixels)
        }
    }

    private static let pixels = 600
}

extension LibraryRoute {
    var appleMusicID: String? {
        switch self {
        case .album(let album): album.appleMusicID
        case .artist(let artist): artist.appleMusicID
        case .singer(let person): person.appleMusicID
        case .writers(let group): group.appleMusicID
        }
    }

    var placeholder: String {
        switch self {
        case .album: "square.stack"
        case .artist: "music.mic"
        case .singer: "person.wave.2"
        case .writers(let group): group.people.count > 1 ? "person.2" : "pencil.line"
        }
    }

    var isPortrait: Bool {
        if case .album = self { false } else { true }
    }

    var identifier: String {
        switch self {
        case .album(let album): "album-\(album.id)"
        case .artist(let artist): "artist-\(artist.id)"
        case .singer(let person): "singer-\(person.id)"
        case .writers(let group): "writers-\(group.id)"
        }
    }

    func summary(in catalog: Catalog) -> String {
        switch self {
        case .album(let album):
            var parts: [String] = []
            if album.artistID != catalog.mainArtist?.id {
                parts.append(album.artistName)
            }
            if let year = album.releaseYear {
                parts.append(String(year))
            }
            parts.append(Counts.songs(album.songIDs.count))
            return parts.joined(separator: " · ")
        case .artist(let artist):
            return "\(Counts.songs(artist.songIDs.count)) · \(Counts.albums(artist.albumIDs.count))"
        case .singer(let person):
            return Counts.songs(catalog.songs(sungBy: person).count)
        case .writers(let group):
            return "\(group.rolesText) · \(Counts.songs(group.songs.count))"
        }
    }
}
#endif
