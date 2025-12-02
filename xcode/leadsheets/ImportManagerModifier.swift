import SwiftUI
import SwiftData

/// A view modifier that handles DataImportManager initialization and initial import
struct ImportManagerModifier: ViewModifier {
    let modelContext: ModelContext
    @Binding var importManager: DataImportManager?

    func body(content: Content) -> some View {
        content
            .onAppear {
                if importManager == nil {
                    importManager = DataImportManager(modelContext: modelContext)
                }
            }
            .task {
                await importManager?.performInitialImport()
            }
    }
}
