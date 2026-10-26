import SwiftUI

struct ContentView: View {
    var body: some View {
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
