import Foundation

/// Orchestrates local conversion of one or more PDF statements: extract layout text with
/// PDFKit, parse rows with `StatementParser`, and assemble a `ConversionResult`. This is the
/// on-device equivalent of the server's `/api/convert` route (minus the auth/usage gating,
/// which the desktop app doesn't need since nothing is metered server-side).
enum StatementConverter {

    enum ConversionError: LocalizedError {
        case noRowsDetected

        var errorDescription: String? {
            switch self {
            case .noRowsDetected:
                return "We opened the file but couldn't detect transaction rows yet. "
                    + "Try a clearer statement, or add the PDF password if it's protected."
            }
        }
    }

    /// Converts the given PDF files locally. `password` is applied to protected PDFs.
    static func convert(fileURLs: [URL], password: String) throws -> ConversionResult {
        var rows: [TransactionRow] = []
        var totalPages = 0
        var fileNames: [String] = []
        let isBatch = fileURLs.count > 1

        for url in fileURLs {
            let extraction = try PDFTextExtractor.extract(from: url, password: password)
            totalPages += extraction.pageCount
            fileNames.append(url.lastPathComponent)

            let parsed = StatementParsing.parseBest(layoutText: extraction.text)
            for var row in parsed {
                // Only tag rows with their source file in batch mode, keeping single-file
                // exports to the clean five-column layout.
                row.sourceFile = isBatch ? url.lastPathComponent : nil
                // Re-key ids so they stay unique across files in a batch.
                rows.append(row)
            }
        }

        // Renumber ids sequentially across the whole (possibly multi-file) result.
        rows = rows.enumerated().map { index, row in
            var copy = row
            copy = TransactionRow(
                id: "row-\(index + 1)",
                sourceFile: row.sourceFile,
                date: row.date,
                valueDate: row.valueDate,
                description: row.description,
                debit: row.debit,
                credit: row.credit,
                balance: row.balance
            )
            return copy
        }

        guard !rows.isEmpty else {
            throw ConversionError.noRowsDetected
        }

        let stem = isBatch
            ? "ledgerlens-batch"
            : normalizeFileStem(fileNames.first ?? "statement.pdf")

        return ConversionResult(
            fileStem: stem,
            pageCount: totalPages,
            rows: rows,
            sourceFiles: fileNames
        )
    }

    /// Port of `normalizeFileStem` from `app/api/convert/route.js`.
    static func normalizeFileStem(_ filename: String) -> String {
        var stem = filename.replacingOccurrences(
            of: "\\.pdf$",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        stem = stem.replacingOccurrences(
            of: "[^a-z0-9-_]+",
            with: "-",
            options: [.regularExpression, .caseInsensitive]
        )
        stem = stem.lowercased()
        stem = stem.replacingOccurrences(of: "^-+|-+$", with: "", options: .regularExpression)
        return stem.isEmpty ? "statement" : stem
    }
}
