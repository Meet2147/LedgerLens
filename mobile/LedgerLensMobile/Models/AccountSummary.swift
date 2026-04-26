import Foundation

struct AccountSummary: Codable, Identifiable {
    var id: String { email }

    let email: String
    let name: String
    let tier: String
    let tierName: String
    let billingCycle: String
    let paymentStatus: String
    let workspaceMembers: [String]
    let monthlyPagesUsed: Int
    let monthlyPageLimit: Int
    let exportFormats: [String]
    let maxFilesPerUpload: Int
    let maxWorkspaceUsers: Int
    let supportLevel: String
    let processingPriority: String
    let trial: TrialSummary
}

struct TrialSummary: Codable {
    let isActive: Bool
    let startedAt: String?
    let endsAt: String?
    let pdfsUsed: Int
    let pdfLimit: Int
    let pagesUsed: Int
    let pageLimit: Int
}
