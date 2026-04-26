import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var authStore: MobileAuthStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear

                ScrollView(showsIndicators: false) {
                    if let account = authStore.account {
                        VStack(spacing: 16) {
                            BrandLockup(style: .compact)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            SummaryCard(account: account)
                            if account.paymentStatus != "paid" {
                                TrialCard(account: account)
                            }
                            TierCapabilityCard(account: account)
                            if account.paymentStatus == "paid" &&
                                account.tier == "personal" &&
                                account.billingCycle == "annual" {
                                UpgradeGapCard()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("LedgerLens")
        }
    }
}

private struct UpgradeGapCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upgrade path")
                .font(.headline)
                .foregroundColor(BrandPalette.ink)

            Text("Professional adds the pieces you do not have yet.")
                .font(.title3.weight(.bold))
                .foregroundColor(BrandPalette.ink)

            Text("Multiple PDFs support, merged batch exports, JSON output, shared workspace seats, and priority processing are all unlocked on Professional.")
                .foregroundColor(BrandPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
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

            Text(account.trial.isActive ? "Active now" : "Upgrade to continue")
                .font(.title2.weight(.bold))
                .foregroundColor(account.trial.isActive ? BrandPalette.sky : BrandPalette.warning)

            Text(trialMessage)
                .foregroundColor(BrandPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private var trialMessage: String {
        let usage = "\(account.trial.pdfsUsed)/\(account.trial.pdfLimit) PDFs • \(account.trial.pagesUsed)/\(account.trial.pageLimit) pages"

        guard account.trial.isActive else {
            return "Your free access window has ended. Choose a paid plan on the web app to keep converting statements."
        }

        if let endsAt = account.trial.endsAt,
           let date = ISO8601DateFormatter().date(from: endsAt) {
            return "\(usage) • Ends \(date.formatted(date: .abbreviated, time: .omitted))"
        }

        return usage
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
