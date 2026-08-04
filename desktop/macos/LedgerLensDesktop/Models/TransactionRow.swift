import Foundation

/// One parsed statement line. Field names and semantics match the web/server model
/// (`components/conversion-result-view.js` and the API response) so exports line up with
/// what the hosted product produces.
struct TransactionRow: Codable, Identifiable, Hashable {
    let id: String
    /// Populated only for multi-file (batch) conversions, mirroring the server behavior.
    var sourceFile: String?
    let date: String
    let valueDate: String
    let description: String
    let debit: String
    let credit: String
    let balance: String

    /// Reconciliation result: false when this row's `balance` doesn't equal the previous
    /// balance ± this row's amount (set by `StatementConverter.reconcile`). Rows that can't be
    /// checked (no prior balance, missing amount/balance) stay `true`.
    var reconciled: Bool = true
}
