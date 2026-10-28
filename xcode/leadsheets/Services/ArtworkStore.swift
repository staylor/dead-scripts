import DeadSheetsKit
import Foundation
import ImageIO
import MusicKit
import Observation
import os

/// Album covers and artist photos from the Apple Music catalog, keyed by Apple Music ID. MusicKit only answers
/// catalog requests once Apple Music access is allowed, so until then there's no artwork.
@Observable
final class ArtworkStore {
    static let shared = ArtworkStore()

    private(set) var artworks: [String: MusicKit.Artwork] = [:]
    private var images: [URL: CGImage] = [:]
    @ObservationIgnored private var downloads: [URL: Task<CGImage?, Never>] = [:]
    @ObservationIgnored private var loading: Task<Void, Never>?

    private init() {}

    func artwork(for appleMusicID: String?) -> MusicKit.Artwork? {
        appleMusicID.flatMap { artworks[$0] }
    }

    func url(for appleMusicID: String?, width: Int, height: Int) -> URL? {
        artwork(for: appleMusicID)?.url(width: width, height: height)
    }

    /// Asks for Apple Music access the first time, then fetches the library's artwork unless it already has it.
    func load() async {
        guard artworks.isEmpty, !Self.isDisabled else { return }
        let loading =
            self.loading
            ?? Task {
                await fetch(from: .bundled)
                self.loading = nil
            }
        self.loading = loading
        await loading.value
    }

    /// The image at this size, once `download` has fetched it.
    func image(for appleMusicID: String?, width: Int, height: Int) -> CGImage? {
        url(for: appleMusicID, width: width, height: height).flatMap { images[$0] }
    }

    /// Fetches the image at this size unless it already has it. Callers asking for one that's on its way share the
    /// download.
    @discardableResult
    func download(_ appleMusicID: String?, width: Int, height: Int) async -> CGImage? {
        guard let url = url(for: appleMusicID, width: width, height: height) else { return nil }
        if let image = images[url] {
            return image
        }
        let download =
            downloads[url]
            ?? Task {
                guard let data = try? await URLSession.shared.data(from: url).0,
                    let source = CGImageSourceCreateWithData(data as CFData, nil)
                else {
                    return nil
                }
                return CGImageSourceCreateImageAtIndex(source, 0, nil)
            }
        downloads[url] = download
        let image = await download.value
        downloads[url] = nil
        images[url] = image
        return image
    }

    private func fetch(from catalog: Catalog) async {
        guard await MusicAuthorization.request() == .authorized else { return }
        do {
            let albums = try await MusicCatalogResourceRequest<MusicKit.Album>(
                matching: \.id,
                memberOf: catalog.albumAppleMusicIDs.map { MusicItemID($0) }
            ).response().items
            let artists = try await MusicCatalogResourceRequest<MusicKit.Artist>(
                matching: \.id,
                memberOf: catalog.artistAppleMusicIDs.map { MusicItemID($0) }
            ).response().items

            var artworks: [String: MusicKit.Artwork] = [:]
            for album in albums {
                artworks[album.id.rawValue] = album.artwork
            }
            for artist in artists {
                artworks[artist.id.rawValue] = artist.artwork
            }
            self.artworks = artworks
        } catch {
            Logger.music.error("Couldn't load artwork: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// UI tests launch with this, so the Apple Music prompt doesn't cover the app.
    private static let isDisabled = ProcessInfo.processInfo.arguments.contains("-noArtwork")
}
