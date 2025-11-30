#if os(iOS) && canImport(CarPlay)
import CarPlay
import SwiftData
import UIKit

@available(iOS 14.0, *)
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    var interfaceController: CPInterfaceController?
    var modelContext: ModelContext?
    
    // MARK: - CPTemplateApplicationSceneDelegate
    
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        print("CarPlay connected!")
        self.interfaceController = interfaceController
        
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
        
        // Try to get the model context from the shared container
        guard let container = try? ModelContainer(for: Song.self, Artist.self, Album.self, Singer.self, Writer.self) else {
            print("Failed to create model container")
            // Return a template with a message
            let emptyItem = CPListItem(text: "No songs available", detailText: "Import songs in the app")
            let section = CPListSection(items: [emptyItem])
            return CPListTemplate(title: "Dead Sheets", sections: [section])
        }
        
        let context = ModelContext(container)
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
                
                // Add handler to open Apple Music when tapped
                item.handler = { [weak self] _, completion in
                    self?.openAppleMusic(for: song)
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
    
    private func openAppleMusic(for song: Song) {
        guard let appleMusicId = song.appleMusicId, !appleMusicId.isEmpty else {
            print("No Apple Music ID for song: \(song.name)")
            return
        }
        
        print("Opening Apple Music for song: \(song.name) with ID: \(appleMusicId)")
        
        // Try multiple URL formats for Apple Music
        let urlStrings = [
            "music://music.apple.com/us/song/\(appleMusicId)",
            "https://music.apple.com/us/song/\(appleMusicId)"
        ]
        
        for urlString in urlStrings {
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    print("Apple Music opened with \(urlString): \(success)")
                }
                return
            }
        }
        
        print("Unable to open Apple Music with ID: \(appleMusicId)")
    }
}
#endif
