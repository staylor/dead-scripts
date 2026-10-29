import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        root
            #if os(iOS) || os(macOS)
        .safeAreaInset(edge: .top, spacing: 0) {
            if !UserData.shared.isAvailable {
                Label {
                    Text(
                        "Your saved favorites and setlists couldn’t be opened. Restart Dead Sheets to try again. You can still browse songs."
                    )
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                }
                .font(.callout)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.bar)
                .accessibilityIdentifier("user-data-unavailable")
            }
        }
            #endif
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
