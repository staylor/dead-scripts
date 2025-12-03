import SwiftUI
import SwiftData

/// A view modifier that handles DataImportManager initialization and initial import
struct ImportManagerModifier: ViewModifier {
    let modelContext: ModelContext
    @Binding var importManager: DataImportManager?

    func body(content: Content) -> some View {
        content
            .task {
                if importManager == nil {
                    importManager = DataImportManager(modelContext: modelContext)
                }
                await importManager?.performInitialImport()
            }
    }
}
