#if os(iOS) || os(macOS)
import SwiftUI

extension View {
    func userDataSaveAlert(_ failure: Binding<UserData.SaveFailure?>) -> some View {
        alert(
            isPresented: Binding(
                get: { failure.wrappedValue != nil },
                set: { if !$0 { failure.wrappedValue = nil } }
            ),
            error: failure.wrappedValue
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { failure in
            Text(failure.failureReason ?? "")
        }
    }
}
#endif
