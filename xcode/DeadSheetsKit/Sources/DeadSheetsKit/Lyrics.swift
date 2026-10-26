import Foundation

extension Song {
    public var lyricLines: [String] {
        lyrics.components(separatedBy: "\n")
    }

    /// Verses and choruses, split on blank lines.
    public var lyricParagraphs: [[String]] {
        var paragraphs: [[String]] = []
        var current: [String] = []
        for line in lyricLines {
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if !current.isEmpty {
                    paragraphs.append(current)
                    current = []
                }
            } else {
                current.append(line)
            }
        }
        if !current.isEmpty {
            paragraphs.append(current)
        }
        return paragraphs
    }

    public static func isChorusHeading(_ line: String) -> Bool {
        line.hasPrefix("Chorus")
    }
}
