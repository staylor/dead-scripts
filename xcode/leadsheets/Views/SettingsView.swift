import SwiftUI
import CloudKit

#if os(iOS) || os(macOS)
struct SettingsView: View {
    @AppStorage("syncWithOtherDevices") private var syncWithOtherDevices = false
    @Environment(\.dismiss) private var dismiss
    @State private var showingICloudAlert = false
    @State private var iCloudStatus: CKAccountStatus = .couldNotDetermine

    var body: some View {
        #if os(macOS)
        Form {
            Toggle("Sync with Other Devices", isOn: syncBinding)
                .toggleStyle(.switch)
        }
        .formStyle(.grouped)
        .frame(width: 300, height: 100)
        .padding()
        .onAppear(perform: checkICloudStatus)
        .alert("iCloud Required", isPresented: $showingICloudAlert) {
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane") {
                    NSWorkspace.shared.open(url)
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
        .onAppear(perform: checkICloudStatus)
        .alert("iCloud Required", isPresented: $showingICloudAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
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
            get: { syncWithOtherDevices },
            set: { newValue in
                if newValue && iCloudStatus != .available {
                    showingICloudAlert = true
                } else {
                    syncWithOtherDevices = newValue
                }
            }
        )
    }

    private func checkICloudStatus() {
        CKContainer.default().accountStatus { status, _ in
            DispatchQueue.main.async {
                iCloudStatus = status
                // If sync was enabled but iCloud is no longer available, disable it
                if syncWithOtherDevices && status != .available {
                    syncWithOtherDevices = false
                }
            }
        }
    }
}
#endif
