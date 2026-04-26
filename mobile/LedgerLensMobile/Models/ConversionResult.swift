import Foundation

struct ConversionResult: Codable {
    let fileStem: String
    let pageCount: Int
    let rows: [TransactionRow]
    let queuePriority: String
    let pagesUsedThisMonth: Int?
    let pagesRemainingThisMonth: Int?
    let exportFormats: [String]
    let trial: TrialUsageResponse
}

struct TransactionRow: Codable, Identifiable {
    let id: String
    let sourceFile: String?
    let date: String
    let description: String
    let debit: String
    let credit: String
    let balance: String
}

struct TrialUsageResponse: Codable {
    let isActive: Bool
    let pdfsUsed: Int?
    let pdfLimit: Int?
    let pagesUsed: Int?
    let pageLimit: Int?
    let endsAt: String?
}
