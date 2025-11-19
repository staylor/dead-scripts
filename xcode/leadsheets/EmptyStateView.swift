import SwiftUI

struct EmptyStateView: View {
    let filter: SearchFilter

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                Text(message)
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }

    private var icon: String {
        switch filter {
        case .allSongs:
            return "doc.text.magnifyingglass"
        case .byAlbum:
            return "opticaldisc"
        case .byArtist:
            return "person.circle"
        case .bySinger:
            return "mic.circle"
        case .byWriter:
            return "person.circle"
        case .covers:
            return "music.note.list"
        }
    }

    private var message: String {
        switch filter {
        case .allSongs:
            return "No songs found"
        case .byAlbum:
            return "No albums found"
        case .byArtist:
            return "No artists found"
        case .bySinger:
            return "No singers found"
        case .byWriter:
            return "No writers found"
        case .covers:
            return "No covers found"
        }
    }
}
