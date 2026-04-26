import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authStore: MobileAuthStore

    var body: some View {
        NavigationStack {
            ScrollView {
                if let account = authStore.account {
                    VStack(spacing: 16) {
                        SummaryCard(account: account)
                        TrialCard(account: account)
                        TierCapabilityCard(account: account)
                    }
                    .padding()
                }
            }
            .navigationTitle("LedgerLens")
        }
    }
}

private struct SummaryCard: View {
    let account: AccountSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(account.tierName)
                .font(.caption.weight(.bold))
                .foregroundColor(.white.opacity(0.9))

            Text(account.email)
                .font(.title3.weight(.bold))
                .foregroundColor(.white)

            Text("\(account.processingPriority.capitalized) processing • \(account.supportLevel)")
                .foregroundColor(.white.opacity(0.88))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [BrandPalette.aqua, BrandPalette.sky, BrandPalette.lilac],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28)
        )
    }
}

private struct TrialCard: View {
    let account: AccountSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trial")
                .font(.headline)
                .foregroundColor(BrandPalette.ink)

            Text(account.trial.isActive ? "Active" : "Ended")
                .font(.title2.weight(.bold))
                .foregroundColor(BrandPalette.sky)

            Text("\(account.trial.pdfsUsed)/\(account.trial.pdfLimit) PDFs • \(account.trial.pagesUsed)/\(account.trial.pageLimit) pages")
                .foregroundColor(BrandPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
    }
}

private struct TierCapabilityCard: View {
    let account: AccountSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan access")
                .font(.headline)
                .foregroundColor(BrandPalette.ink)

            Text("\(account.maxFilesPerUpload) file(s) per upload")
            Text("\(account.monthlyPagesUsed)/\(account.monthlyPageLimit) monthly pages")
            Text("Exports: \(account.exportFormats.joined(separator: ", ").uppercased())")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
        .foregroundColor(BrandPalette.muted)
    }
}
