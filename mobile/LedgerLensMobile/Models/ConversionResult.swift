import Foundation

struct ConversionResult: Codable, Identifiable, Hashable {
    let fileStem: String
    let pageCount: Int
    let rows: [TransactionRow]
    let queuePriority: String
    let pagesUsedThisMonth: Int?
    let pagesRemainingThisMonth: Int?
    let exportFormats: [String]
    let trial: TrialUsageResponse

    var id: String {
        "\(fileStem)-\(pageCount)-\(rows.count)-\(queuePriority)"
    }
}

struct TransactionRow: Codable, Identifiable, Hashable {
    let id: String
    let sourceFile: String?
    let date: String
    let description: String
    let debit: String
    let credit: String
    let balance: String
}

struct TrialUsageResponse: Codable, Hashable {
    let isActive: Bool
    let pdfsUsed: Int?
    let pdfLimit: Int?
    let pagesUsed: Int?
    let pageLimit: Int?
    let endsAt: String?
}
