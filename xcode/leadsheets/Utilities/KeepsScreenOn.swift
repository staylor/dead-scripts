import SwiftUI

extension View {
    /// Stops the display from dimming or sleeping while the view is on screen, so a sheet stays
    /// readable on a music stand.
    func keepsScreenOn(_ isEnabled: Bool = true) -> some View {
        modifier(KeepsScreenOn(isEnabled: isEnabled))
    }
}

private struct KeepsScreenOn: ViewModifier {
    let isEnabled: Bool

    #if os(macOS)
    @State private var activity: (any NSObjectProtocol)?
    #endif

    func body(content: Content) -> some View {
        content
            .onAppear { update(isEnabled) }
            .onChange(of: isEnabled) { _, isEnabled in update(isEnabled) }
            .onDisappear { update(false) }
    }

    private func update(_ keepsOn: Bool) {
        #if os(macOS)
        if keepsOn, activity == nil {
            activity = ProcessInfo.processInfo.beginActivity(
                options: [.idleDisplaySleepDisabled, .userInitiated],
                reason: "Showing a lead sheet"
            )
        } else if !keepsOn, let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
        #elseif os(iOS) || os(tvOS)
        UIApplication.shared.isIdleTimerDisabled = keepsOn
        #endif
    }
}

enum SettingsKey {
    static let keepsScreenOn = "keepsScreenOn"
}
