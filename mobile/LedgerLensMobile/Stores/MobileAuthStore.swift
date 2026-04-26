import Foundation

@MainActor
final class MobileAuthStore: ObservableObject {
    @Published var account: AccountSummary?
    @Published var email: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading = false

    var isLoggedIn: Bool {
        account != nil
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
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        guard let account else { return }

        do {
            self.account = try await MobileAPI.shared.fetchAccountSummary(email: account.email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        account = nil
        errorMessage = ""
    }
}
