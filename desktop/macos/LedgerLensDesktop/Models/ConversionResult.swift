import Foundation

/// The outcome of converting one or more PDF statements locally.
struct ConversionResult: Identifiable, Hashable {
    let id = UUID()
    /// Sanitized base name used for the default export filename (e.g. `hdfc-statement`).
    let fileStem: String
    let pageCount: Int
    let rows: [TransactionRow]
    /// File names that produced these rows, in upload order.
    let sourceFiles: [String]
    /// True if any page was read via OCR (a scanned statement) rather than a text layer.
    var usedOCR: Bool = false
    /// Number of rows whose running balance didn't reconcile (balance ≠ previous ± amount).
    var unreconciledCount: Int = 0

    /// True once more than one statement contributed rows — controls whether the
    /// `sourceFile` column is included in exports, matching the web app.
    var isBatch: Bool { sourceFiles.count > 1 }
}
