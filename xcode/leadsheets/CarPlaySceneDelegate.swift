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
        Task {
            await MusicPlayerService.shared.requestAuthorization()
        }
        interfaceController.setRootTemplate(makeSongList(), animated: false) { _, error in
            if let error {
                Logger.carPlay.error("Couldn't show the song list: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    private func makeSongList() -> CPListTemplate {
        let songs = Catalog.bundled.songs
        guard !songs.isEmpty else {
            let section = CPListSection(items: [CPListItem(text: "No songs available", detailText: nil)])
            return CPListTemplate(title: "Dead Sheets", sections: [section])
        }

        let songsByInitial = Dictionary(grouping: songs) { song in
            let initial = song.title.prefix(1).uppercased()
            return initial.rangeOfCharacter(from: .letters) == nil ? "#" : initial
        }
        let sections = songsByInitial.keys.sorted().map { initial in
            let items = (songsByInitial[initial] ?? []).map { song in
                let item = CPListItem(text: song.title, detailText: song.artistName)
                item.handler = { [weak self] _, completion in
                    self?.play(song)
                    completion()
                }
                return item
            }
            return CPListSection(items: items, header: initial, sectionIndexTitle: initial)
        }
        return CPListTemplate(title: "Dead Sheets", sections: sections)
    }

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
