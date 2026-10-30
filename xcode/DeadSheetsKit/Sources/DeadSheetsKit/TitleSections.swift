import Foundation

public struct TitleSection: Equatable, Sendable {
    public let heading: String
    public let songs: [Song]
}

extension Sequence<Song> {
    /// Sections under the first letter of each title, ignoring case and accents, with "#" for digits and symbols.
    /// Headings follow the order of the songs, so they match the catalog's title order.
    public func titleSections() -> [TitleSection] {
        var headings: [String] = []
        var songsByHeading: [String: [Song]] = [:]
        for song in self {
            let heading = Self.heading(for: song.title)
            if songsByHeading[heading] == nil {
                headings.append(heading)
            }
            songsByHeading[heading, default: []].append(song)
        }
        return headings.map { TitleSection(heading: $0, songs: songsByHeading[$0] ?? []) }
    }

    private static func heading(for title: String) -> String {
        guard let first = title.first, first.isLetter else { return "#" }
        let folded = String(first).folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
        return folded.prefix(1).uppercased()
    }
}
