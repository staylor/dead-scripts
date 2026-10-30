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

    private enum Library {
        case songs([Song], alphabetic: Bool)
        case albums([Album])

        var count: Int {
            switch self {
            case .songs(let songs, _): songs.count
            case .albums(let albums): albums.count
            }
        }
    }

    private func makeSongList() -> CPListTemplate {
        let template = list(title: "Songs", library: .songs(Catalog.bundled.songs, alphabetic: true))
        template.tabTitle = "Songs"
        template.tabImage = UIImage(systemName: "music.note.list")
        template.emptyViewTitleVariants = ["No Songs"]
        return template
    }

    private func makeAlbumList() -> CPListTemplate {
        let template = list(title: "Albums", library: .albums(Catalog.bundled.albums))
        template.tabTitle = "Albums"
        template.tabImage = UIImage(systemName: "square.stack")
        return template
    }

    private func showSongs(on album: Album) {
        let template = list(title: album.title, library: .songs(Catalog.bundled.songs(on: album), alphabetic: false))
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    private func list(title: String, library: Library) -> CPListTemplate {
        let template = CPListTemplate(title: title, sections: [])
        showPage(0, of: library, in: template)
        return template
    }

    private func showPage(_ index: Int, of library: Library, in template: CPListTemplate) {
        let page = CatalogPage(itemCount: library.count, maximumItemCount: CPListTemplate.maximumItemCount, index: index)
        var items: [CPListItem]
        switch library {
        case .songs(let songs, let alphabetic):
            let visible = Array(songs[page.range])
            if alphabetic, page.previous == nil, page.next == nil {
                let groups = Dictionary(grouping: visible) { song in
                    let initial = song.title.prefix(1).uppercased()
                    return initial.rangeOfCharacter(from: .letters) == nil ? "#" : initial
                }
                if groups.count <= CPListTemplate.maximumSectionCount {
                    template.updateSections(
                        groups.keys.sorted().map { initial in
                            CPListSection(items: (groups[initial] ?? []).map(makeItem), header: initial, sectionIndexTitle: initial)
                        })
                    return
                }
            }
            items = visible.map(makeItem)
        case .albums(let albums):
            items = albums[page.range].map(makeItem)
        }

        func pageItem(_ title: String, index: Int) -> CPListItem {
            let item = CPListItem(text: title, detailText: nil)
            item.handler = { [weak self, weak template] _, completion in
                if let template {
                    self?.showPage(index, of: library, in: template)
                }
                completion()
            }
            return item
        }
        if let previous = page.previous {
            items.insert(pageItem("Previous Page", index: previous), at: 0)
        }
        if let next = page.next {
            items.append(pageItem("Next Page", index: next))
        }
        template.updateSections([CPListSection(items: items)])
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
