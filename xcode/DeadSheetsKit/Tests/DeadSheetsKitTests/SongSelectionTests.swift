import Foundation
import Testing

@testable import DeadSheetsKit

struct SongSelectionTests {
    @Test func ignoresDuplicatesAndOutOfOrderDeliveries() {
        var state = SongSelectionState()
        let newest = selection("ripple", at: 20)
        #expect(state.receive(newest) == true)
        #expect(state.receive(newest) == false)
        #expect(state.receive(selection("althea", at: 10)) == false)
        #expect(state.latest == newest)
    }

    @Test func choosingTheSameSongAgainIsANewSelection() {
        var state = SongSelectionState()
        #expect(state.receive(selection("ripple", at: 10)) == true)
        #expect(state.receive(selection("ripple", at: 20)) == true)
    }

    @Test func lateRemoteSelectionsDoNotReplaceALocalChoice() {
        var state = SongSelectionState()
        let local = state.select(songID: "ripple", at: date(20))
        #expect(state.receive(selection("althea", at: 10)) == false)
        #expect(state.latest == local)
        #expect(state.pending == local)
    }

    @Test func pendingSelectionsCoalesceWithoutAnOlderAcknowledgementDroppingTheLatest() {
        var state = SongSelectionState()
        let first = state.select(songID: "ripple", at: date(10))
        let second = state.select(songID: "althea", at: date(20))
        state.acknowledge(first)
        #expect(state.pending == second)
        state.acknowledge(second)
        #expect(state.pending == nil)
        #expect(state.latest == second)
    }

    @Test func aNewerRemoteSelectionReplacesAnUnsentLocalChoice() {
        var state = SongSelectionState()
        state.select(songID: "ripple", at: date(10))
        let remote = selection("althea", at: 20)
        #expect(state.receive(remote) == true)
        #expect(state.pending == nil)
        #expect(state.latest == remote)
    }

    @Test func localSelectionsStayOrderedWhenTheClockStandsStillOrMovesBack() {
        var state = SongSelectionState()
        let first = state.select(songID: "ripple", at: date(20))
        let second = state.select(songID: "ripple", at: date(20))
        let third = state.select(songID: "althea", at: date(10))
        #expect(second.date > first.date)
        #expect(third.date > second.date)
        #expect(state.pending == third)
    }

    @Test func forwardingKeepsTheOriginalTimestampAndDoesNotReviveAnOldSelection() {
        var state = SongSelectionState()
        let event = selection("ripple", at: 20)
        #expect(state.forward(event) == true)
        #expect(state.pending == event)
        #expect(state.forward(selection("althea", at: 10)) == false)
        #expect(state.forward(event) == false)
        #expect(state.pending == event)
    }

    @Test func invalidSelectionsDoNotPoisonTheOrdering() {
        var state = SongSelectionState()
        #expect(state.receive(selection("", at: 10)) == false)
        #expect(state.receive(selection("ripple", at: .infinity)) == false)
        #expect(state.receive(selection("ripple", at: .nan)) == false)
        #expect(state.receive(selection("althea", at: 10)) == true)
    }

    private func selection(_ songID: Song.ID, at timestamp: TimeInterval) -> SongSelection {
        SongSelection(songID: songID, date: date(timestamp))
    }

    private func date(_ timestamp: TimeInterval) -> Date {
        Date(timeIntervalSince1970: timestamp)
    }
}
