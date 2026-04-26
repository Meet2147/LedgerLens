import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authStore: MobileAuthStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                Spacer(minLength: 24)

                VStack(spacing: 14) {
                    BrandLockup(style: .compact)

                    Text("Sign in with the same email you use on the web app and keep your conversions synced across devices.")
                        .foregroundColor(BrandPalette.muted)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                }

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Email address")
                            .font(.headline)
                            .foregroundColor(BrandPalette.ink)

                        TextField(
                            "",
                            text: $authStore.email,
                            prompt: Text("you@example.com").foregroundColor(BrandPalette.muted.opacity(0.7))
                        )
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundColor(BrandPalette.ink)
                            .tint(BrandPalette.sky)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(BrandPalette.surfaceStrong, in: RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(BrandPalette.sky.opacity(0.16), lineWidth: 1)
                            )
                    }

                    Button {
                        Task { await authStore.login() }
                    } label: {
                        Text(authStore.isLoading ? "Signing in..." : "Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [BrandPalette.aqua, BrandPalette.sky],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 20)
                            )
                            .foregroundColor(.white)
                    }
                    .disabled(authStore.isLoading)

                    if !authStore.errorMessage.isEmpty {
                        StatusNotice(
                            title: "We couldn't sign you in",
                            message: authStore.errorMessage,
                            tone: .error
                        )
                    }
                }
                .padding(24)
                .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 30))
                .shadow(color: .black.opacity(0.06), radius: 26, y: 18)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Included in your trial")
                        .font(.headline)
                        .foregroundColor(BrandPalette.ink)

                    TrialFeatureRow(icon: "clock", text: "7 full days of access")
                    TrialFeatureRow(icon: "doc", text: "Convert up to 5 PDF statements")
                    TrialFeatureRow(icon: "doc.text", text: "Process up to 50 total pages")
                }
                .foregroundColor(BrandPalette.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.04), radius: 18, y: 10)

                Spacer(minLength: 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 24)
        .safeAreaPadding(.top, 28)
        .toolbarColorScheme(.light, for: .navigationBar)
    }
}

private struct TrialFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(BrandPalette.sky)
                .frame(width: 22)

            Text(text)
                .font(.body)
        }
    }
}

struct StatusNotice: View {
    enum Tone {
        case error
        case warning
        case info

        var accent: Color {
            switch self {
            case .error:
                return BrandPalette.danger
            case .warning:
                return BrandPalette.warning
            case .info:
                return BrandPalette.sky
            }
        }

        var icon: String {
            switch self {
            case .error:
                return "exclamationmark.triangle.fill"
            case .warning:
                return "clock.badge.exclamationmark"
            case .info:
                return "info.circle.fill"
            }
        }
    }

    let title: String
    let message: String
    let tone: Tone

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tone.icon)
                .foregroundColor(tone.accent)
                .font(.headline)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(BrandPalette.ink)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(BrandPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(tone.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(tone.accent.opacity(0.18), lineWidth: 1)
        )
    }
}
