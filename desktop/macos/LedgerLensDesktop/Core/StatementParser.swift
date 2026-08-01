import Foundation

/// A faithful Swift port of `lib/statement-parser.js` (`parseTransactionsFromLayoutText`
/// and its helpers). The regexes, ignore rules, and control flow mirror the web/server
/// parser exactly so the desktop app produces identical rows for the same layout text.
///
/// The one difference from the server is *where the layout text comes from*: the server
/// shells out to `pdftotext -layout`; the desktop app reconstructs equivalent
/// column-preserving text on-device with PDFKit (see `PDFTextExtractor`). Nothing about a
/// user's statement ever leaves the machine.
enum StatementParser {
    // Mirrors the JS constants.
    private static let datePattern = "\\d{2}/\\d{2}/\\d{4}"
    private static let moneyToken = "(?:-|[\\d,]+\\.\\d{2}(?:CR|DR)?)"

    private static let dateRegex = try! NSRegularExpression(pattern: datePattern)

    private static let leadingNumericRegex = try! NSRegularExpression(
        pattern: "^\\d[\\d,.\\sA-Z()/-]+$"
    )

    private static let transactionLineRegex: NSRegularExpression = {
        let pattern = "^(\(datePattern))\\s+(\(datePattern))\\s+(.+?)\\s+"
            + "(\(moneyToken))\\s+(\(moneyToken))\\s+(\(moneyToken))\\s+(\(moneyToken))\\s*$"
        return try! NSRegularExpression(pattern: pattern)
    }()

    // MARK: - Public entry point

    /// Parses transaction rows from layout-preserving text, matching the server parser and
    /// capping the result at 5000 rows just like `convertStatement`.
    static func parse(layoutText text: String) -> [TransactionRow] {
        Array(parseTransactions(from: text).prefix(5000))
    }

    // MARK: - Helpers (ports of the JS functions)

    private static func normalizeWhitespace(_ value: String) -> String {
        value.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanMoney(_ value: String) -> String {
        let normalized = normalizeWhitespace(value)

        if normalized.isEmpty || normalized == "-" {
            return ""
        }

        if normalized.hasSuffix("DR") {
            return "-" + normalized.dropLast(2)
        }

        if normalized.hasSuffix("CR") {
            return String(normalized.dropLast(2))
        }

        return normalized
    }

    private static func matches(_ regex: NSRegularExpression, _ line: String) -> Bool {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        return regex.firstMatch(in: line, range: range) != nil
    }

    private static func isIgnorableLine(_ line: String) -> Bool {
        if line.isEmpty
            || line == "\u{0c}"
            || line.hasPrefix("Page no.")
            || line.hasPrefix("Statement Summary")
            || line.hasPrefix("Please do not share your ATM")
            || line.hasPrefix("If your account is operated")
            || line.hasPrefix("This is a computer generated statement")
            || line == "Balance"
            || line == "Welcome:"
            || line.hasPrefix("Account Summary")
            || line.hasPrefix("STATEMENT OF ACCOUNT")
            || line.hasPrefix("Brought Forward")
            || line.hasPrefix("Total Debits")
            || line.hasPrefix("Total Credits")
            || line.hasPrefix("Closing Balance")
            || line.hasPrefix("anyone via email")
            || line.hasPrefix("Bank never asks for such information") {
            return true
        }

        // `(!DATE_PATTERN.test(line) && /^\d[\d,.\sA-Z()/-]+$/.test(line))`
        return !matches(dateRegex, line) && matches(leadingNumericRegex, line)
    }

    // MARK: - Core parser (port of parseTransactionsFromLayoutText)

    private struct Pending {
        let date: String
        let valueDate: String
        var descriptionParts: [String]
        let debit: String
        let credit: String
        let balance: String
    }

    private static func parseTransactions(from text: String) -> [TransactionRow] {
        let lines = text
            .replacingOccurrences(of: "\u{0c}", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.replacingOccurrences(of: "\u{0000}", with: "") }
            .map { line -> String in
                // Trim trailing whitespace only (mirrors `.replace(/\s+$/g, "")`).
                var chars = Array(line)
                while let last = chars.last, last == " " || last == "\t" || last == "\r" {
                    chars.removeLast()
                }
                return String(chars)
            }

        var rows: [TransactionRow] = []
        var pending: Pending?
        var carryoverDescriptionParts: [String] = []
        var awaitingNextRowAfterPageBreak = false

        func flushPending() {
            guard let current = pending else { return }
            rows.append(
                TransactionRow(
                    id: "row-\(rows.count + 1)",
                    sourceFile: nil,
                    date: current.date,
                    valueDate: current.valueDate,
                    description: normalizeWhitespace(current.descriptionParts.joined(separator: " ")),
                    debit: current.debit,
                    credit: current.credit,
                    balance: current.balance
                )
            )
            pending = nil
        }

        for index in lines.indices {
            let rawLine = lines[index]
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            if line.hasPrefix("Page no.") {
                flushPending()
                awaitingNextRowAfterPageBreak = true
                carryoverDescriptionParts = []
                continue
            }

            if isIgnorableLine(line) {
                continue
            }

            if let groups = capture(transactionLineRegex, line) {
                flushPending()

                pending = Pending(
                    date: groups[1],
                    valueDate: groups[2],
                    descriptionParts: carryoverDescriptionParts + [groups[3]],
                    debit: cleanMoney(groups[5]),
                    credit: cleanMoney(groups[6]),
                    balance: cleanMoney(groups[7])
                )
                carryoverDescriptionParts = []
                awaitingNextRowAfterPageBreak = false
                continue
            }

            if awaitingNextRowAfterPageBreak && pending == nil {
                carryoverDescriptionParts.append(line)
                continue
            }

            if pending == nil {
                continue
            }

            if matches(dateRegex, line) {
                flushPending()
                continue
            }

            var nextMeaningfulLine = ""
            var cursor = index + 1
            while cursor < lines.count {
                let candidate = lines[cursor].trimmingCharacters(in: .whitespacesAndNewlines)
                if candidate.isEmpty || isIgnorableLine(candidate) {
                    cursor += 1
                    continue
                }
                nextMeaningfulLine = candidate
                break
            }

            if !nextMeaningfulLine.isEmpty && matches(transactionLineRegex, nextMeaningfulLine) {
                carryoverDescriptionParts = [line]
                flushPending()
                awaitingNextRowAfterPageBreak = false
                continue
            }

            pending?.descriptionParts.append(line)
        }

        flushPending()
        return rows
    }

    /// Returns capture groups (index 0 = whole match) as strings, or nil if no match.
    private static func capture(_ regex: NSRegularExpression, _ line: String) -> [String]? {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }

        var groups: [String] = []
        for i in 0..<match.numberOfRanges {
            let groupRange = match.range(at: i)
            if groupRange.location == NSNotFound, let swiftRange = Range(groupRange, in: line) {
                groups.append(String(line[swiftRange]))
            } else if let swiftRange = Range(groupRange, in: line) {
                groups.append(String(line[swiftRange]))
            } else {
                groups.append("")
            }
        }
        return groups
    }
}
