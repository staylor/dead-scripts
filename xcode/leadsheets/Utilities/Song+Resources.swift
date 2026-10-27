import DeadSheetsKit
import Foundation

extension Song {
    var sheetURL: URL? {
        Bundle.main.url(forResource: sheetResourceName, withExtension: "pdf", subdirectory: "pdfs")
    }

    private var sheetResourceName: String {
        (sheetFileName as NSString).deletingPathExtension
    }
}
