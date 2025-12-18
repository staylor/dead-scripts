#if os(iOS) && canImport(CarPlay)
import CarPlay
import SwiftData
import UIKit

@available(iOS 14.0, *)
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    var interfaceController: CPInterfaceController?
    var modelContext: ModelContext?
    private var importObserver: NSObjectProtocol?

    deinit {
        if let observer = importObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
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

        // Listen for import completion to refresh the list
        importObserver = NotificationCenter.default.addObserver(
            forName: .songsDidImport,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshSongList()
        }
    }

    private func refreshSongList() {
        guard let interfaceController = interfaceController else { return }
        print("Refreshing CarPlay song list after import...")
        let updatedTemplate = createSongListTemplate()
        interfaceController.setRootTemplate(updatedTemplate, animated: true, completion: nil)
    }
    
    private func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        print("CarPlay disconnected")
        self.interfaceController = nil
    }
    
    // MARK: - Template Creation
    
    private func createSongListTemplate() -> CPListTemplate {
        print("Creating song list template...")

        // Use the shared model container
        let context = ModelContext(SharedModelContainer.shared)
        self.modelContext = context
        
        // Fetch all songs
        let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.name)])
        guard let songs = try? context.fetch(descriptor), !songs.isEmpty else {
            print("No songs found in database")
            // Return a template with a message
            let emptyItem = CPListItem(text: "No songs available", detailText: "Import songs in the app")
            let section = CPListSection(items: [emptyItem])
            return CPListTemplate(title: "Dead Sheets", sections: [section])
        }
        
        print("Found \(songs.count) songs")
        
        // Group songs by first letter
        let groupedSongs = Dictionary(grouping: songs) { song -> String in
            let firstChar = song.name.prefix(1).uppercased()
            return firstChar.rangeOfCharacter(from: .letters) != nil ? firstChar : "#"
        }
        
        // Create sections
        let sections = groupedSongs.keys.sorted().map { letter -> CPListSection in
            let songsInSection = groupedSongs[letter]?.sorted { $0.name < $1.name } ?? []
            
            let items = songsInSection.map { song -> CPListItem in
                let item = CPListItem(
                    text: song.name,
                    detailText: song.artist?.name ?? ""
                )

                // Capture only the values needed, not the SwiftData model
                let appleMusicId = song.appleMusicId
                let songName = song.name

                // Add handler to open Apple Music when tapped
                item.handler = { [weak self] _, completion in
                    self?.openAppleMusic(id: appleMusicId, name: songName)
                    completion()
                }

                return item
            }
            
            return CPListSection(items: items, header: letter, sectionIndexTitle: letter)
        }
        
        let listTemplate = CPListTemplate(title: "Dead Sheets", sections: sections)
        print("Template created with \(sections.count) sections")
        return listTemplate
    }
    
    // MARK: - Helper Methods

    private func openAppleMusic(id appleMusicId: String?, name songName: String) {
        guard let appleMusicId = appleMusicId, !appleMusicId.isEmpty else {
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
