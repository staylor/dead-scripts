import Foundation
import Testing

@testable import Dead_Sheets

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct MusicPlayerTests {
    @Test func latestRequestWinsWithoutClearingItsLoadingState() async {
        let backend = TestMusicPlayer()
        let firstResponse = TestSuspension<PlaybackResult>()
        let latestResponse = TestSuspension<PlaybackResult>()
        backend.responses = ["first": firstResponse, "latest": latestResponse]
        let player = MusicPlayerService(startPlayback: backend.start, pausePlayback: backend.pause)
        let first = Task { await player.start(appleMusicID: "first", title: "First") }
        await firstResponse.started.wait()
        let middleEntered = TestSignal()
        let middle = Task {
            middleEntered.signal()
            return await player.start(appleMusicID: "middle", title: "Middle")
        }
        await middleEntered.wait()
        let latestEntered = TestSignal()
        let latest = Task {
            latestEntered.signal()
            return await player.start(appleMusicID: "latest", title: "Latest")
        }
        await latestEntered.wait()
        #expect(player.loadingSongID == "latest")
        #expect(backend.started == ["first"])

        firstResponse.resume(returning: .playing)
        await latestResponse.started.wait()
        #expect(await first.value == .cancelled)
        #expect(await middle.value == .cancelled)
        #expect(player.loadingSongID == "latest")
        latestResponse.resume(returning: .playing)
        #expect(await latest.value == .playing)
        #expect(backend.started == ["first", "latest"])
        #expect(backend.playingID == "latest")
        #expect(player.loadingSongID == nil)
    }

    @Test func pauseStopsAStartThatFinishesAfterCancellation() async {
        let backend = TestMusicPlayer()
        let response = TestSuspension<PlaybackResult>()
        backend.responses["first"] = response
        let player = MusicPlayerService(startPlayback: backend.start, pausePlayback: backend.pause)
        let request = Task { await player.start(appleMusicID: "first", title: "First") }
        await response.started.wait()
        player.pause()
        #expect(player.loadingSongID == nil)
        response.resume(returning: .playing)
        #expect(await request.value == .cancelled)
        #expect(backend.playingID == nil)
    }

    @Test func playAfterPauseWaitsForTheOldRequestToFinishStopping() async {
        let backend = TestMusicPlayer()
        let response = TestSuspension<PlaybackResult>()
        backend.responses["first"] = response
        let player = MusicPlayerService(startPlayback: backend.start, pausePlayback: backend.pause)
        let first = Task { await player.start(appleMusicID: "first", title: "First") }
        await response.started.wait()
        player.pause()
        let entered = TestSignal()
        let latest = Task {
            entered.signal()
            return await player.start(appleMusicID: "latest", title: "Latest")
        }
        await entered.wait()
        #expect(backend.started == ["first"])
        response.resume(returning: .playing)
        #expect(await first.value == .cancelled)
        #expect(await latest.value == .playing)
        #expect(backend.playingID == "latest")
    }

    @Test(arguments: Self.problems)
    func cancelledRequestsDoNotPresentProblems(_ problem: PlaybackResult) async {
        let backend = TestMusicPlayer()
        let response = TestSuspension<PlaybackResult>()
        backend.responses["first"] = response
        let player = MusicPlayerService(startPlayback: backend.start, pausePlayback: backend.pause)
        let first = Task { await player.play(appleMusicID: "first", title: "First") }
        await response.started.wait()
        let entered = TestSignal()
        let latest = Task {
            entered.signal()
            await player.play(appleMusicID: "latest", title: "Latest")
        }
        await entered.wait()
        response.resume(returning: problem)
        await first.value
        await latest.value
        #expect(player.failure == nil)
        #expect(player.subscriptionOfferSongID == nil)
        #expect(backend.playingID == "latest")
    }

    @Test(arguments: Self.problems)
    func currentRequestsStillPresentProblems(_ problem: PlaybackResult) async {
        let backend = TestMusicPlayer()
        backend.results["first"] = problem
        let player = MusicPlayerService(startPlayback: backend.start, pausePlayback: backend.pause)
        await player.play(appleMusicID: "first", title: "First")
        switch problem {
        case .failed(let failure):
            #expect(player.failure == failure)
            #expect(player.subscriptionOfferSongID == nil)
        case .needsSubscription:
            #expect(player.failure == nil)
            #expect(player.subscriptionOfferSongID == "first")
        case .playing, .cancelled:
            Issue.record("Expected a playback problem")
        }
        #expect(player.loadingSongID == nil)
    }

    @Test func cancellingTheCallerAlsoCancelsPlayback() async {
        let backend = TestMusicPlayer()
        let response = TestSuspension<PlaybackResult>()
        backend.responses["first"] = response
        let player = MusicPlayerService(startPlayback: backend.start, pausePlayback: backend.pause)
        let request = Task { await player.start(appleMusicID: "first", title: "First") }
        await response.started.wait()
        request.cancel()
        response.resume(returning: .playing)
        #expect(await request.value == .cancelled)
        #expect(backend.playingID == nil)
        #expect(player.loadingSongID == nil)
    }

    private nonisolated static let problems: [PlaybackResult] = [
        .needsSubscription,
        .failed(PlaybackFailure(songTitle: "First", appleMusicID: "first", reason: .notAuthorized)),
    ]
}

@MainActor
private final class TestMusicPlayer {
    var responses: [String: TestSuspension<PlaybackResult>] = [:]
    var results: [String: PlaybackResult] = [:]
    var started: [String] = []
    var playingID: String?

    func start(appleMusicID: String, title: String) async -> PlaybackResult {
        started.append(appleMusicID)
        do {
            let result: PlaybackResult
            if let response = responses[appleMusicID] {
                result = try await response.value()
            } else {
                result = results[appleMusicID] ?? .playing
            }
            if result == .playing {
                playingID = appleMusicID
            }
            return result
        } catch {
            Issue.record(error)
            return .cancelled
        }
    }

    func pause() {
        playingID = nil
    }
}
