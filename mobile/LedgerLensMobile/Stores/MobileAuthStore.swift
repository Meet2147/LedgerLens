import Foundation
import SwiftUI

@MainActor
final class MobileAuthStore: ObservableObject {
    @Published var account: AccountSummary?
    @Published var email: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading = false
    @Published var isBootstrapping = false

    @AppStorage("ledgerlens.mobile.didCompleteOnboarding") var didCompleteOnboarding = false
    @AppStorage("ledgerlens.mobile.savedAccount") private var savedAccountData = ""

    var isLoggedIn: Bool {
        account != nil
    }

    init() {
        if
            let data = savedAccountData.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(AccountSummary.self, from: data)
        {
            account = decoded
            email = decoded.email
        }
    }

    func login() async {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Enter the same email you use on the LedgerLens web app."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            let summary = try await MobileAPI.shared.login(email: email)
            account = summary
            email = summary.email
            persistAccount(summary)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        guard let account else { return }

        do {
            let refreshed = try await MobileAPI.shared.fetchAccountSummary(email: account.email)
            self.account = refreshed
            persistAccount(refreshed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func bootstrap() async {
        guard !isBootstrapping else { return }
        guard let account else { return }

        isBootstrapping = true
        await refresh()
        isBootstrapping = false
    }

    func logout() {
        account = nil
        savedAccountData = ""
        errorMessage = ""
    }

    private func persistAccount(_ summary: AccountSummary) {
        if let data = try? JSONEncoder().encode(summary),
           let string = String(data: data, encoding: .utf8) {
            savedAccountData = string
        }
    }
}
