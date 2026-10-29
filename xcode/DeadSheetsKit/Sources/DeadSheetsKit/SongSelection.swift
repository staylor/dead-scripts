import Foundation

public struct SongSelection: Equatable, Sendable {
    public let songID: Song.ID
    public let date: Date

    public init(songID: Song.ID, date: Date) {
        self.songID = songID
        self.date = date
    }
}

public struct SongSelectionState: Sendable {
    public private(set) var latest: SongSelection?
    public private(set) var pending: SongSelection?

    public init() {}

    @discardableResult
    public mutating func select(songID: Song.ID, at date: Date) -> SongSelection {
        // A new local choice must follow the last event even if a peer’s clock is ahead.
        let date = max(date, latest?.date.addingTimeInterval(0.001) ?? date)
        let selection = SongSelection(songID: songID, date: date)
        latest = selection
        pending = selection
        return selection
    }

    @discardableResult
    public mutating func receive(_ selection: SongSelection) -> Bool {
        guard !selection.songID.isEmpty, selection.date.timeIntervalSince1970.isFinite,
            latest.map({ selection.date > $0.date }) ?? true
        else { return false }
        latest = selection
        pending = nil
        return true
    }

    @discardableResult
    public mutating func forward(_ selection: SongSelection) -> Bool {
        guard receive(selection) else { return false }
        pending = selection
        return true
    }

    public mutating func acknowledge(_ selection: SongSelection) {
        if pending == selection {
            pending = nil
        }
    }
}
