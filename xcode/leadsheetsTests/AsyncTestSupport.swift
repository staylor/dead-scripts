import Testing

@MainActor
final class TestSignal {
    private var isSignaled = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func signal() {
        isSignaled = true
        let waiting = continuations
        continuations = []
        for continuation in waiting {
            continuation.resume()
        }
    }

    func wait() async {
        guard !isSignaled else { return }
        await withCheckedContinuation { continuations.append($0) }
    }
}

@MainActor
final class TestSuspension<Value: Sendable> {
    let started = TestSignal()
    private var continuation: CheckedContinuation<Value, any Error>?

    func value() async throws -> Value {
        try await withCheckedThrowingContinuation {
            continuation = $0
            started.signal()
        }
    }

    func resume(returning value: Value) {
        guard let continuation else {
            Issue.record("The operation was not waiting")
            return
        }
        self.continuation = nil
        continuation.resume(returning: value)
    }
}
