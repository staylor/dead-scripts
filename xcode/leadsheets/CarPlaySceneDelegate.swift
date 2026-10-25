#if os(iOS) && canImport(CarPlay)
import CarPlay
import DeadSheetsKit
import UIKit

@available(iOS 14.0, *)
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    var interfaceController: CPInterfaceController?

    // MARK: - CPTemplateApplicationSceneDelegate
    
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        print("CarPlay connected!")
        self.interfaceController = interfaceController

        // Request MusicKit authorization early
        Task {
            _ = await MusicPlayerService.shared.requestAuthorization()
        }

        // Set up the root template
        let rootTemplate = createSongListTemplate()
        interfaceController.setRootTemplate(rootTemplate, animated: false, completion: { success, error in
            if let error = error {
                print("Error setting root template: \(error)")
            } else {
                print("Root template set successfully")
            }
        })
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        print("CarPlay disconnected")
        self.interfaceController = nil
    }
    
    // MARK: - Template Creation
    
    private func createSongListTemplate() -> CPListTemplate {
        let songs = Catalog.bundled.songs
        guard !songs.isEmpty else {
            let emptyItem = CPListItem(text: "No songs available", detailText: nil)
            let section = CPListSection(items: [emptyItem])
            return CPListTemplate(title: "Dead Sheets", sections: [section])
        }
        
        // Group songs by first letter
        let groupedSongs = Dictionary(grouping: songs) { song -> String in
            let firstChar = song.title.prefix(1).uppercased()
            return firstChar.rangeOfCharacter(from: .letters) != nil ? firstChar : "#"
        }
        
        // Create sections
        let sections = groupedSongs.keys.sorted().map { letter -> CPListSection in
            let items = (groupedSongs[letter] ?? []).map { song -> CPListItem in
                let item = CPListItem(text: song.title, detailText: song.artistName)
                item.handler = { [weak self] _, completion in
                    self?.openAppleMusic(id: song.appleMusicID, name: song.title)
                    completion()
                }
                return item
            }
            
            return CPListSection(items: items, header: letter, sectionIndexTitle: letter)
        }
        
        return CPListTemplate(title: "Dead Sheets", sections: sections)
    }
    
    // MARK: - Helper Methods

    private func openAppleMusic(id appleMusicId: String?, name songName: String) {
        guard let appleMusicId else {
            print("No Apple Music ID for song: \(songName)")
            return
        }

        Task {
            await MusicPlayerService.shared.play(appleMusicId: appleMusicId, songName: songName)

            // Push to Now Playing screen after playback starts
            await MainActor.run {
                let nowPlayingTemplate = CPNowPlayingTemplate.shared
                interfaceController?.pushTemplate(nowPlayingTemplate, animated: true, completion: nil)
            }
        }
    }
}
#endif
