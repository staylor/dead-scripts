import SwiftUI

#if os(iOS) || os(macOS)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showingICloudAlert = false

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
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
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
                Toggle("Sync with Other Devices", isOn: syncBinding)
            } footer: {
                Text("Songs you open appear on your other iPhone, iPad, Mac and Apple Watch signed in to the same iCloud account.")
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
