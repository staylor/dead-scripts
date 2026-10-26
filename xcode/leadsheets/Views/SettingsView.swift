import SwiftUI

#if os(iOS) || os(macOS)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showingICloudAlert = false
    @AppStorage(SettingsKey.keepsScreenOn) private var keepsScreenOn = true

    private let cloudSync = CloudSyncManager.shared

    var body: some View {
        #if os(macOS)
        form
            .formStyle(.grouped)
            .frame(width: 420)
            .fixedSize(horizontal: false, vertical: true)
        #else
        NavigationStack {
            form
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                }
        }
        #endif
    }

    private var form: some View {
        Form {
            Section {
                Toggle("Keep Screen On", isOn: $keepsScreenOn)
            } footer: {
                Text("While a lead sheet is open, the screen doesn’t dim or lock.")
            }

            Section {
                Toggle("Sync with Other Devices", isOn: syncBinding)
            } footer: {
                Text("Songs you open appear on your other iPhone, iPad, Mac and Apple Watch signed in to the same iCloud account.")
            }

            Section {
                LabeledContent("Version", value: Self.version)
                Link("Privacy Policy", destination: Self.privacyPolicyURL)
                Link("Report a Problem", destination: Self.issuesURL)
            } header: {
                Text("About")
            } footer: {
                Text("Lyrics are by the writers credited on each song. Album artwork and playback come from Apple Music.")
            }
        }
        .task(disableSyncIfICloudIsUnavailable)
        .alert("iCloud Required", isPresented: $showingICloudAlert) {
            Button("Open \(Self.settingsApp)") {
                if let url = Self.iCloudSettingsURL {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Sign in to iCloud in \(Self.settingsApp) to sync song selections across your devices.")
        }
    }

    private var syncBinding: Binding<Bool> {
        Binding(
            get: { cloudSync.isEnabled },
            set: { enable in
                guard enable else {
                    cloudSync.isEnabled = false
                    return
                }
                Task {
                    if await cloudSync.isAccountAvailable() {
                        cloudSync.isEnabled = true
                    } else {
                        showingICloudAlert = true
                    }
                }
            }
        )
    }

    private func disableSyncIfICloudIsUnavailable() async {
        if cloudSync.isEnabled, await !cloudSync.isAccountAvailable() {
            cloudSync.isEnabled = false
        }
    }

    private static let version: String = {
        let info = Bundle.main.infoDictionary
        let marketingVersion = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(marketingVersion) (\(build))"
    }()

    private static let privacyPolicyURL = URL(string: "https://github.com/staylor/dead-scripts/blob/main/xcode/PRIVACY.md")!
    private static let issuesURL = URL(string: "https://github.com/staylor/dead-scripts/issues")!

    #if os(macOS)
    private static let settingsApp = "System Settings"
    private static let iCloudSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane")
    #else
    private static let settingsApp = "Settings"
    private static let iCloudSettingsURL = URL(string: UIApplication.openSettingsURLString)
    #endif
}

#Preview {
    SettingsView()
}
#endif
