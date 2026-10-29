import DeadSheetsKit
import Foundation

extension Song {
    var sheetURL: URL? {
        Bundle.main.url(forResource: sheetFileName, withExtension: nil, subdirectory: "pdfs")
    }
}
