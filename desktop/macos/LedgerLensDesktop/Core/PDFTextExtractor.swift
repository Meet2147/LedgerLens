import Foundation
import PDFKit

/// On-device replacement for `pdftotext`.
///
/// The server parser depends on layout-preserving text: each transaction on its own line,
/// fields left-to-right, separated by whitespace. PDFKit's `page.string` already delivers
/// exactly that for text-based statements — one line per statement row, single spaces
/// between columns — which the parser's `\s+`-based regexes consume directly. (We tried
/// reconstructing columns from per-glyph `characterBounds`, but PDFKit returns degenerate
/// rects for many glyphs, so `page.string` is both simpler and more reliable.)
///
/// Everything here runs locally — the PDF bytes never leave the machine.
enum PDFTextExtractor {

    enum ExtractionError: LocalizedError {
        case cannotOpen
        case locked
        case incorrectPassword

        var errorDescription: String? {
            switch self {
            case .cannotOpen:
                return "We couldn't open that file. Make sure it's a valid PDF."
            case .locked:
                return "This PDF is password protected. Enter its password and try again."
            case .incorrectPassword:
                return "The PDF password is incorrect. Please re-enter it and try again."
            }
        }
    }

    struct Extraction {
        let pageCount: Int
        let text: String
    }

    /// Opens (and if needed unlocks) the PDF, then returns layout-preserving text plus the
    /// page count. Mirrors the shape returned by the server's `extractTextFromPdf`.
    static func extract(from url: URL, password: String) throws -> Extraction {
        guard let document = PDFDocument(url: url) else {
            throw ExtractionError.cannotOpen
        }
        return try extract(from: document, password: password)
    }

    static func extract(from data: Data, password: String) throws -> Extraction {
        guard let document = PDFDocument(data: data) else {
            throw ExtractionError.cannotOpen
        }
        return try extract(from: document, password: password)
    }

    static func extract(from document: PDFDocument, password: String) throws -> Extraction {
        if document.isLocked {
            let trimmed = password
            guard !trimmed.isEmpty else { throw ExtractionError.locked }
            guard document.unlock(withPassword: trimmed) else {
                throw ExtractionError.incorrectPassword
            }
        }

        var pageTexts: [String] = []
        pageTexts.reserveCapacity(document.pageCount)

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            pageTexts.append(layoutText(for: page))
        }

        // Join pages with a form feed, matching `pdftotext` page separation. The parser
        // turns form feeds into newlines, so this only marks page boundaries.
        let text = pageTexts.joined(separator: "\u{0c}")
        return Extraction(pageCount: document.pageCount, text: text)
    }

    // MARK: - Layout text

    /// Layout-preserving text for a single page. PDFKit's `page.string` already returns one
    /// line per statement row with whitespace-separated columns, which is what the parser
    /// expects.
    static func layoutText(for page: PDFPage) -> String {
        page.string ?? ""
    }
}
