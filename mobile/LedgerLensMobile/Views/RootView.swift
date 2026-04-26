import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authStore: MobileAuthStore

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.white, BrandPalette.background, BrandPalette.sky.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if !authStore.didCompleteOnboarding {
                OnboardingView()
            } else if authStore.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(.light)
    }
}

private struct OnboardingView: View {
    @EnvironmentObject private var authStore: MobileAuthStore
    @State private var pageIndex = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Convert statements without cleanup",
            message: "Upload bank PDFs, unlock protected files, and get transaction-ready rows without wrestling with formatting.",
            accent: .aqua,
            systemImage: "doc.text.magnifyingglass"
        ),
        OnboardingPage(
            title: "One account across web and mobile",
            message: "Your trial, plan, exports, and usage stay in sync so you can start on desktop and finish on your phone.",
            accent: .sky,
            systemImage: "arrow.triangle.2.circlepath.iphone"
        ),
        OnboardingPage(
            title: "Private by default",
            message: "We do not store your uploaded PDFs or extracted transaction data. Use LedgerLens for fast conversion, then move on.",
            accent: .lilac,
            systemImage: "lock.shield"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 18)

            HStack {
                Spacer()

                Button(pageIndex == pages.count - 1 ? "Done" : "Skip") {
                    authStore.didCompleteOnboarding = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(BrandPalette.muted)
            }
            .padding(.horizontal, 24)

            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 28) {
                        Spacer(minLength: 16)

                        BrandHeroMark(accent: page.accent)
                            .frame(width: 156, height: 156)

                        VStack(spacing: 14) {
                            Text(page.title)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(BrandPalette.ink)
                                .multilineTextAlignment(.center)

                            Text(page.message)
                                .font(.title3)
                                .foregroundColor(BrandPalette.muted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }

                        onboardingFeatureCard(page: page)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == pageIndex ? BrandPalette.sky : BrandPalette.sky.opacity(0.18))
                        .frame(width: index == pageIndex ? 28 : 8, height: 8)
                }
            }
            .padding(.bottom, 22)

            Button {
                if pageIndex == pages.count - 1 {
                    authStore.didCompleteOnboarding = true
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        pageIndex += 1
                    }
                }
            } label: {
                Text(pageIndex == pages.count - 1 ? "Get started" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [BrandPalette.aqua, BrandPalette.sky],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 22)
                    )
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func onboardingFeatureCard(page: OnboardingPage) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: page.systemImage)
                .font(.title2)
                .foregroundColor(page.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text("LedgerLens mobile")
                    .font(.headline)
                    .foregroundColor(BrandPalette.ink)

                Text(page.shortDetail)
                    .font(.subheadline)
                    .foregroundColor(BrandPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.04), radius: 18, y: 10)
    }
}

struct BrandHeroMark: View {
    var accent: BrandAccent = .sky

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.18), BrandPalette.sky.opacity(0.16), BrandPalette.lilac.opacity(0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.white.opacity(0.92))
                .padding(20)
                .shadow(color: .black.opacity(0.05), radius: 16, y: 8)

            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [BrandPalette.aqua, BrandPalette.sky, BrandPalette.lilac],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)

                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("LedgerLens")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BrandPalette.aqua, BrandPalette.sky, BrandPalette.lilac],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
    }

    private var accentColor: Color {
        accent.color
    }
}

enum BrandAccent {
    case aqua
    case sky
    case lilac

    var color: Color {
        switch self {
        case .aqua:
            return BrandPalette.aqua
        case .sky:
            return BrandPalette.sky
        case .lilac:
            return BrandPalette.lilac
        }
    }
}

private struct OnboardingPage {
    let title: String
    let message: String
    let accent: BrandAccent
    let systemImage: String

    var accentColor: Color {
        accent.color
    }

    var shortDetail: String {
        switch accent {
        case .aqua:
            return "Convert statements quickly, with preview-first review before you export."
        case .sky:
            return "Stay in sync with the same plan, limits, and account identity across devices."
        case .lilac:
            return "Keep document handling minimal and controlled while moving fast."
        }
    }
}
