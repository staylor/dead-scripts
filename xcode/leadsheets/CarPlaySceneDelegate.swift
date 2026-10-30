#if os(iOS) && canImport(CarPlay)
import CarPlay
import DeadSheetsKit
import os
import UIKit

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        let tabs = CPTabBarTemplate(templates: [makeSongList(), makeAlbumList()])
        interfaceController.setRootTemplate(tabs, animated: false) { _, error in
            if let error {
                Logger.carPlay.error("Couldn't show the library: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    // MARK: - Templates

    private func makeSongList() -> CPListTemplate {
        let template = CPListTemplate(title: "Songs", sections: sections(for: Catalog.bundled.songs))
        template.tabTitle = "Songs"
        template.tabImage = UIImage(systemName: "music.note.list")
        template.emptyViewTitleVariants = ["No Songs"]
        return template
    }

    private func makeAlbumList() -> CPListTemplate {
        let template = CPListTemplate(title: "Albums", sections: [CPListSection(items: Catalog.bundled.albums.map(makeItem))])
        template.tabTitle = "Albums"
        template.tabImage = UIImage(systemName: "square.stack")
        return template
    }

    private func showSongs(on album: Album) {
        let songs = Catalog.bundled.songs(on: album)
        let template = CPListTemplate(title: album.title, sections: [CPListSection(items: songs.map(makeItem))])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    /// Lists stay whole rather than paged: some cars cut lists to 12 items while driving, and iOS applies that limit.
    private func sections(for songs: [Song]) -> [CPListSection] {
        let sections = songs.titleSections()
        guard sections.count <= CPListTemplate.maximumSectionCount else {
            return [CPListSection(items: songs.map(makeItem))]
        }
        return sections.map { CPListSection(items: $0.songs.map(makeItem), header: $0.heading, sectionIndexTitle: $0.heading) }
    }

    private func makeItem(for album: Album) -> CPListItem {
        let item = CPListItem(text: album.title, detailText: LibraryRoute.album(album).summary(in: .bundled), image: nil)
        showArtwork(album.appleMusicID, on: item)
        item.accessoryType = .disclosureIndicator
        item.handler = { [weak self] _, completion in
            self?.showSongs(on: album)
            completion()
        }
        return item
    }

    private func makeItem(for song: Song) -> CPListItem {
        let item = CPListItem(text: song.title, detailText: song.artistAndAlbum, image: nil)
        showArtwork(song.albumAppleMusicID, on: item)
        item.handler = { [weak self] _, completion in
            self?.play(song)
            completion()
        }
        return item
    }

    private func showArtwork(_ appleMusicID: String?, on item: CPListItem) {
        guard let appleMusicID else { return }
        let scale = interfaceController?.carTraitCollection.displayScale ?? 2
        let size = CPListItem.maximumImageSize
        Task {
            let store = ArtworkStore.shared
            await store.load()
            let image = await store.download(appleMusicID, width: Int(size.width * scale), height: Int(size.height * scale))
            item.setImage(image.map { UIImage(cgImage: $0, scale: scale, orientation: .up) })
        }
    }

    // MARK: - Playback

    private func play(_ song: Song) {
        guard let appleMusicID = song.appleMusicID else {
            showAlert("“\(song.title)” isn’t in Apple Music.")
            return
        }
        Task {
            switch await MusicPlayerService.shared.start(appleMusicID: appleMusicID, title: song.title) {
            case .playing:
                showNowPlaying()
            case .needsSubscription:
                showAlert("Playing songs requires an Apple Music subscription.")
            case .failed(let failure):
                showAlert(failure.errorDescription ?? "Couldn’t play “\(song.title)”.")
            }
        }
    }

    private func showNowPlaying() {
        guard let interfaceController, interfaceController.topTemplate !== CPNowPlayingTemplate.shared else { return }
        interfaceController.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
    }

    private func showAlert(_ message: String) {
        let dismiss = CPAlertAction(title: "OK", style: .cancel) { [weak self] _ in
            self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
        }
        interfaceController?.presentTemplate(
            CPAlertTemplate(titleVariants: [message], actions: [dismiss]),
            animated: true,
            completion: nil
        )
    }
}
#endif
