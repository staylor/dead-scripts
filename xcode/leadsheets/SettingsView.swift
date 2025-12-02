import SwiftUI

#if os(iOS) || os(macOS)
struct SettingsView: View {
    @AppStorage("syncWithOtherDevices") private var syncWithOtherDevices = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        #if os(macOS)
        Form {
            Toggle("Sync with Other Devices", isOn: $syncWithOtherDevices)
                .toggleStyle(.switch)
        }
        .formStyle(.grouped)
        .frame(width: 300, height: 100)
        .padding()
        #else
        NavigationStack {
            Form {
                Section {
                    Toggle("Sync with Other Devices", isOn: $syncWithOtherDevices)
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
        #endif
    }
}
#endif
