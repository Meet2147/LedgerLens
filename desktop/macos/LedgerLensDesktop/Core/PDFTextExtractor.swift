import Foundation
import PDFKit
import Vision
import CoreGraphics

/// On-device text extraction for PDF statements.
///
/// Two paths, both fully local:
///   1. **Text-layer PDFs** — `PDFKit.page.string` returns one line per statement row with
///      whitespace-separated columns, which the parser consumes directly.
///   2. **Scanned / image-only PDFs** — when a page has no usable text layer, the page is
///      rendered to a bitmap and OCR'd with Apple's **Vision** framework (`VNRecognizeTextRequest`).
///      OCR runs on-device — scanned statements never leave the machine either.
///
/// The Vision output is re-assembled into layout-preserving lines (group by vertical position,
/// order left-to-right) so the same parser handles OCR'd pages unchanged.
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
        /// True if any page was read via OCR (a scan) rather than a text layer — lets the UI
        /// warn that OCR'd numbers deserve an extra glance.
        let usedOCR: Bool
    }

    // MARK: - Public entry points

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
            let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw ExtractionError.locked }
            guard document.unlock(withPassword: trimmed) else {
                throw ExtractionError.incorrectPassword
            }
        }

        var pageTexts: [String] = []
        pageTexts.reserveCapacity(document.pageCount)
        var usedOCR = false

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }

            let layer = layoutText(for: page)
            if hasUsableText(layer) {
                pageTexts.append(layer)
            } else {
                // No text layer on this page — OCR it locally.
                let ocr = ocrText(for: page)
                if !ocr.isEmpty { usedOCR = true }
                pageTexts.append(ocr)
            }
        }

        let text = pageTexts.joined(separator: "\u{0c}")
        return Extraction(pageCount: document.pageCount, text: text, usedOCR: usedOCR)
    }

    // MARK: - Text layer

    /// Layout-preserving text for a single page from its embedded text layer.
    static func layoutText(for page: PDFPage) -> String {
        page.string ?? ""
    }

    /// A page has usable text if it carries more than a trivial amount of characters. Scans
    /// return empty or a few stray glyphs; a real statement page has hundreds.
    private static func hasUsableText(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 24
    }

    // MARK: - OCR (Vision)

    /// Renders the page to a bitmap and OCRs it with Vision, returning layout-preserving text.
    static func ocrText(for page: PDFPage) -> String {
        guard let cgImage = render(page, scale: 3.0) else { return "" }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false   // never "autocorrect" amounts / reference codes
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return ""
        }

        guard let observations = request.results, !observations.isEmpty else { return "" }
        return reconstructLines(from: observations)
    }

    /// Rasterizes a PDF page to a CGImage at `scale`× its point size (higher = better OCR).
    private static func render(_ page: PDFPage, scale: CGFloat) -> CGImage? {
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }

        let pixelWidth = Int((bounds.width * scale).rounded())
        let pixelHeight = Int((bounds.height * scale).rounded())

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }

        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -bounds.minX, y: -bounds.minY)
        page.draw(with: .mediaBox, to: context)

        return context.makeImage()
    }

    /// Groups Vision observations into lines (by vertical position), orders each line
    /// left-to-right, and joins them into the same layout-preserving text the parser expects.
    private static func reconstructLines(from observations: [VNRecognizedTextObservation]) -> String {
        struct Item { let text: String; let minX: CGFloat; let midY: CGFloat; let height: CGFloat }

        let items: [Item] = observations.compactMap { obs in
            guard let candidate = obs.topCandidates(1).first else { return nil }
            let box = obs.boundingBox // normalized, origin bottom-left, y increases upward
            return Item(text: candidate.string, minX: box.minX, midY: box.midY, height: box.height)
        }
        guard !items.isEmpty else { return "" }

        let heights = items.map { $0.height }.sorted()
        let medianHeight = heights[heights.count / 2]
        let tolerance = max(medianHeight * 0.6, 0.004)

        // Higher midY == higher on the page == earlier line.
        let sorted = items.sorted { $0.midY > $1.midY }

        var lines: [[Item]] = []
        var current: [Item] = []
        var baseline: CGFloat = sorted[0].midY

        for item in sorted {
            if current.isEmpty {
                current = [item]; baseline = item.midY
            } else if abs(item.midY - baseline) <= tolerance {
                current.append(item)
                baseline = (baseline * CGFloat(current.count - 1) + item.midY) / CGFloat(current.count)
            } else {
                lines.append(current)
                current = [item]; baseline = item.midY
            }
        }
        if !current.isEmpty { lines.append(current) }

        let rendered = lines.map { line in
            line.sorted { $0.minX < $1.minX }.map { $0.text }.joined(separator: " ")
        }
        return rendered.joined(separator: "\n")
    }
}
