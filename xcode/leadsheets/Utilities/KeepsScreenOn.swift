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

    @State private var isHolding = false

    func body(content: Content) -> some View {
        content
            .onAppear { hold(isEnabled) }
            .onChange(of: isEnabled) { _, isEnabled in hold(isEnabled) }
            .onDisappear { hold(false) }
    }

    private func hold(_ holds: Bool) {
        guard holds != isHolding else { return }
        isHolding = holds
        ScreenWake.holders += holds ? 1 : -1
    }
}

/// Counts the views keeping the screen on. A sheet that replaces another appears before the old one disappears,
/// and another window can be showing one too.
private enum ScreenWake {
    static var holders = 0 {
        didSet {
            #if os(macOS)
            if holders > 0, activity == nil {
                activity = ProcessInfo.processInfo.beginActivity(
                    options: [.idleDisplaySleepDisabled, .userInitiated],
                    reason: "Showing a lead sheet"
                )
            } else if holders == 0, let activity {
                ProcessInfo.processInfo.endActivity(activity)
                self.activity = nil
            }
            #elseif os(iOS) || os(tvOS)
            UIApplication.shared.isIdleTimerDisabled = holders > 0
            #endif
        }
    }

    #if os(macOS)
    private static var activity: (any NSObjectProtocol)?
    #endif
}

enum SettingsKey {
    static let keepsScreenOn = "keepsScreenOn"
}
