import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authStore: MobileAuthStore

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("LedgerLens")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BrandPalette.aqua, BrandPalette.sky, BrandPalette.lilac],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Log in with the same email you use on the web app.")
                    .foregroundColor(BrandPalette.muted)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Email address")
                    .font(.headline)
                    .foregroundColor(BrandPalette.ink)

                TextField("you@example.com", text: $authStore.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
            }

            Button {
                Task { await authStore.login() }
            } label: {
                Text(authStore.isLoading ? "Signing in..." : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [BrandPalette.aqua, BrandPalette.sky],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .foregroundColor(.white)
            }
            .disabled(authStore.isLoading)

            if !authStore.errorMessage.isEmpty {
                Text(authStore.errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("7-day trial", systemImage: "clock")
                Label("5 PDFs total", systemImage: "doc")
                Label("50 pages total", systemImage: "doc.text")
            }
            .foregroundColor(BrandPalette.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 22))
        }
        .padding(24)
    }
}
