import SwiftUI

struct MobileAccountView: View {
    @EnvironmentObject private var authStore: MobileAuthStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear

                ScrollView(showsIndicators: false) {
                    if let account = authStore.account {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(account.email)
                                    .font(.title3.weight(.bold))
                                Text("Tier: \(account.tierName)")
                                Text("Billing: \(account.billingCycle.capitalized)")
                                Text("Payment: \(account.paymentStatus.capitalized)")
                                Text("Workspace seats: \(account.maxWorkspaceUsers)")
                                Text("Members: \(account.workspaceMembers.count + 1)")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
                            .foregroundColor(BrandPalette.muted)

                            Button("Refresh account") {
                                Task { await authStore.refresh() }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(BrandPalette.sky)

                            Button("Log out") {
                                authStore.logout()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Account")
        }
    }
}
