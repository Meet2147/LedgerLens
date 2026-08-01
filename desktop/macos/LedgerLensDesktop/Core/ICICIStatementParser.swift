import Foundation

/// Parser template for ICICI Bank "Statement of Transactions" / OpTransactionHistory PDFs.
///
/// That layout is very different from the one `StatementParser` handles, so it gets its own
/// template (see `StatementParsing.parseBest`, which auto-selects). Structure:
///
///   <S.No> <DD.MM.YYYY> <payee prefix>          ← transaction start
///   UPI/....../....                             ← 0..n remark continuation lines
///   Bank/650.../ICI....                         ← (UPI ref, split across lines)
///   45.00 32363.05                              ← <amount> <balance>  (amount line)
///
/// The amount line is sometimes appended to a remark line (e.g. loan EMI rows). Withdrawal
/// vs deposit isn't encoded in the collapsed text, so it's inferred from balance movement.
enum ICICIStatementParser {

    private static let money = "\\d[\\d,]*\\.\\d{2}"

    private static let startRegex = try! NSRegularExpression(
        pattern: "^(\\d{1,6})\\s+(\\d{2}\\.\\d{2}\\.\\d{4})\\s+(.+)$"
    )

    /// Captures leading text plus the trailing run of 1+ money tokens on a line.
    private static let amountTailRegex = try! NSRegularExpression(
        pattern: "^(.*?)((?:\(money)\\s+)*\(money))\\s*$"
    )

    private struct Draft {
        let date: String
        var remarks: [String]
        var amount: Double
        var balance: Double
        var amountText: String
        var balanceText: String
    }

    static func parse(layoutText text: String) -> [TransactionRow] {
        let lines = text
            .replacingOccurrences(of: "\u{0c}", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var drafts: [Draft] = []
        var current: Draft?

        func flush() {
            guard let draft = current, draft.amountText.isEmpty == false else { current = nil; return }
            drafts.append(draft)
            current = nil
        }

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }

            if let groups = capture(startRegex, line) {
                flush()
                current = Draft(
                    date: normalizeDate(groups[2]),
                    remarks: [groups[3]],
                    amount: 0,
                    balance: 0,
                    amountText: "",
                    balanceText: ""
                )
                continue
            }

            // Everything before the first start line is statement preamble — skip it.
            guard current != nil else { continue }

            if isNoiseLine(line) { continue }

            if let tail = capture(amountTailRegex, line) {
                let leading = tail[1].trimmingCharacters(in: .whitespaces)
                let numbers = tail[2]
                    .split(whereSeparator: { $0 == " " || $0 == "\t" })
                    .map(String.init)
                    .filter { !$0.isEmpty }

                if numbers.count >= 2 {
                    if !leading.isEmpty && !isNoiseLine(leading) {
                        current?.remarks.append(leading)
                    }
                    let balanceText = numbers[numbers.count - 1]
                    // 3 tokens => explicit withdrawal, deposit, balance; otherwise a single
                    // amount whose direction we resolve later from balance movement.
                    let amountText = numbers.count >= 3 ? numbers[0] : numbers[numbers.count - 2]
                    current?.amountText = amountText
                    current?.balanceText = balanceText
                    current?.amount = parseMoney(amountText)
                    current?.balance = parseMoney(balanceText)
                    flush()
                    continue
                }
                // A single trailing money token isn't an amount line here — treat as remark.
            }

            current?.remarks.append(line)
        }

        flush()
        return buildRows(from: drafts)
    }

    // MARK: - Row assembly + debit/credit inference

    private static func buildRows(from drafts: [Draft]) -> [TransactionRow] {
        var rows: [TransactionRow] = []
        var previousBalance: Double?

        for (index, draft) in drafts.enumerated() {
            let isDeposit: Bool
            if let prev = previousBalance {
                // Balance up => money in (deposit/credit); down => money out (withdrawal/debit).
                isDeposit = draft.balance > prev + 0.001
            } else {
                // First row's direction can't be derived from a prior balance; default to a
                // withdrawal, the overwhelmingly common case for these statements.
                isDeposit = false
            }

            rows.append(
                TransactionRow(
                    id: "row-\(index + 1)",
                    sourceFile: nil,
                    date: draft.date,
                    valueDate: draft.date,
                    description: normalizeWhitespace(draft.remarks.joined(separator: " ")),
                    debit: isDeposit ? "" : draft.amountText,
                    credit: isDeposit ? draft.amountText : "",
                    balance: draft.balanceText
                )
            )

            previousBalance = draft.balance
        }

        return Array(rows.prefix(5000))
    }

    // MARK: - Helpers

    private static func normalizeDate(_ value: String) -> String {
        value.replacingOccurrences(of: ".", with: "/")
    }

    private static func parseMoney(_ value: String) -> Double {
        Double(value.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private static func normalizeWhitespace(_ value: String) -> String {
        value.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isNoiseLine(_ line: String) -> Bool {
        line.hasPrefix("www.icici")
            || line.hasPrefix("Please call")
            || line.hasPrefix("Never share")
            || line.hasPrefix("S No.")
            || line.hasPrefix("Date Cheque")
            || line.hasPrefix("Transaction Remarks")
            || line == "Withdrawal"
            || line == "Deposit"
            || line == "Balance"
            || line == "Amount (INR)"
            || line == "(INR)"
            || line.hasPrefix("Sincerly")
            || line.hasPrefix("Team ICICI")
            || line.hasPrefix("This is a system generated")
            || line.hasPrefix("Legends for")
            || line.hasPrefix("Statement of Transactions")
    }

    private static func capture(_ regex: NSRegularExpression, _ line: String) -> [String]? {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range) else { return nil }
        var groups: [String] = []
        for i in 0..<match.numberOfRanges {
            if let r = Range(match.range(at: i), in: line) {
                groups.append(String(line[r]))
            } else {
                groups.append("")
            }
        }
        return groups
    }
}

/// Chooses the best template for a given statement by trying each and keeping whichever
/// detects the most rows. The templates key off mutually exclusive date formats
/// (slash-dates vs dot-dates), so the one that matches wins and the other returns nothing.
enum StatementParsing {
    static func parseBest(layoutText text: String) -> [TransactionRow] {
        let original = StatementParser.parse(layoutText: text)
        let icici = ICICIStatementParser.parse(layoutText: text)
        return icici.count > original.count ? icici : original
    }
}
