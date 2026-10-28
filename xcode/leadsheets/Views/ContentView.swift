import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        root
            .task(id: scenePhase) {
                if scenePhase == .active {
                    await ArtworkStore.shared.load()
                }
            }
    }

    @ViewBuilder private var root: some View {
        #if os(tvOS)
        TVRootView()
        #else
        SplitRootView()
        #endif
    }
}

#Preview {
    ContentView()
}
