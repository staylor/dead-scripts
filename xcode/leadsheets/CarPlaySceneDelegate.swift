#if os(iOS) && canImport(CarPlay)
import CarPlay
import DeadSheetsKit
import os
import UIKit

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var thumbnails: [String: UIImage] = [:]

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        Task {
            await MusicPlayerService.shared.requestAuthorization()
        }
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
        thumbnails = [:]
    }

    // MARK: - Templates

    private func makeSongList() -> CPListTemplate {
        let songsByInitial = Dictionary(grouping: Catalog.bundled.songs) { song in
            let initial = song.title.prefix(1).uppercased()
            return initial.rangeOfCharacter(from: .letters) == nil ? "#" : initial
        }
        let sections = songsByInitial.keys.sorted().map { initial in
            CPListSection(
                items: (songsByInitial[initial] ?? []).map(makeItem),
                header: initial,
                sectionIndexTitle: initial
            )
        }
        let template = CPListTemplate(title: "Songs", sections: sections)
        template.tabTitle = "Songs"
        template.tabImage = UIImage(systemName: "music.note.list")
        template.emptyViewTitleVariants = ["No Songs"]
        return template
    }

    private func makeAlbumList() -> CPListTemplate {
        let catalog = Catalog.bundled
        let items = catalog.albums.map { album in
            var detail = Counts.songs(album.songIDs.count)
            if let year = album.releaseYear {
                detail = "\(year) · \(detail)"
            }
            let item = CPListItem(text: album.title, detailText: detail, image: thumbnail(for: album.coverFileName))
            item.accessoryType = .disclosureIndicator
            item.handler = { [weak self] _, completion in
                self?.showSongs(on: album)
                completion()
            }
            return item
        }
        let template = CPListTemplate(title: "Albums", sections: [CPListSection(items: items)])
        template.tabTitle = "Albums"
        template.tabImage = UIImage(systemName: "square.stack")
        return template
    }

    private func showSongs(on album: Album) {
        let songs = Catalog.bundled.songs(on: album)
        let template = CPListTemplate(title: album.title, sections: [CPListSection(items: songs.map(makeItem))])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    private func makeItem(for song: Song) -> CPListItem {
        let item = CPListItem(text: song.title, detailText: song.albumTitle, image: thumbnail(for: song.coverFileName))
        item.handler = { [weak self] _, completion in
            self?.play(song)
            completion()
        }
        return item
    }

    private func thumbnail(for fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        if let thumbnail = thumbnails[fileName] {
            return thumbnail
        }
        let scale = interfaceController?.carTraitCollection.displayScale ?? 2
        let size = CPListItem.maximumImageSize
        let thumbnail = ImageLoader.loadImage(named: fileName)?
            .preparingThumbnail(of: CGSize(width: size.width * scale, height: size.height * scale))
        thumbnails[fileName] = thumbnail
        return thumbnail
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
