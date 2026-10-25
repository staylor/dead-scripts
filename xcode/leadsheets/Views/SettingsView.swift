import SwiftUI

#if os(iOS) || os(macOS)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showingICloudAlert = false

    private let cloudSync = CloudSyncManager.shared

    var body: some View {
        #if os(macOS)
        Form {
            Toggle("Sync with Other Devices", isOn: syncBinding)
                .toggleStyle(.switch)
        }
        .formStyle(.grouped)
        .frame(width: 300, height: 100)
        .padding()
        .task(disableSyncIfICloudIsUnavailable)
        .alert("iCloud Required", isPresented: $showingICloudAlert) {
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane") {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Sign in to iCloud in System Settings to sync song selections across your devices.")
        }
        #else
        NavigationStack {
            Form {
                Section {
                    Toggle("Sync with Other Devices", isOn: syncBinding)
                } footer: {
                    Text("When enabled, song selections will sync across your iPhone, iPad, Mac, and Apple Watch.")
                }
            }
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
        .task(disableSyncIfICloudIsUnavailable)
        .alert("iCloud Required", isPresented: $showingICloudAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Sign in to iCloud in Settings to sync song selections across your devices.")
        }
        #endif
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
}
#endif
