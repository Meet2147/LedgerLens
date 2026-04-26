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

            if authStore.isBootstrapping {
                VStack(spacing: 18) {
                    BrandLockup(style: .hero)
                    ProgressView()
                        .tint(BrandPalette.sky)
                    Text("Restoring your LedgerLens workspace…")
                        .foregroundColor(BrandPalette.muted)
                }
            } else if !authStore.didCompleteOnboarding {
                OnboardingView()
            } else if authStore.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(.light)
        .task {
            await authStore.bootstrap()
        }
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

                        BrandLockup(style: .hero)

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

struct BrandLockup: View {
    enum Style {
        case hero
        case compact

        var markSize: CGFloat {
            switch self {
            case .hero:
                return 92
            case .compact:
                return 72
            }
        }

        var titleFont: Font {
            switch self {
            case .hero:
                return .system(size: 28, weight: .bold, design: .rounded)
            case .compact:
                return .system(size: 22, weight: .bold, design: .rounded)
            }
        }

        var spacing: CGFloat {
            switch self {
            case .hero:
                return 18
            case .compact:
                return 14
            }
        }
    }

    var style: Style = .compact

    var body: some View {
        VStack(spacing: style.spacing) {
            LedgerLensMark()
                .frame(width: style.markSize, height: style.markSize)

            Text("LedgerLens")
                .font(style.titleFont)
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

struct LedgerLensMark: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let unit = size / 64

            ZStack {
                RoundedRectangle(cornerRadius: 18 * unit, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [BrandPalette.aqua, BrandPalette.sky, BrandPalette.lilac],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56 * unit, height: 56 * unit)

                Path { path in
                    path.move(to: CGPoint(x: 21 * unit, y: 18 * unit))
                    path.addLine(to: CGPoint(x: 29 * unit, y: 18 * unit))
                    path.addLine(to: CGPoint(x: 29 * unit, y: 42 * unit))
                    path.addLine(to: CGPoint(x: 47 * unit, y: 42 * unit))
                    path.addLine(to: CGPoint(x: 47 * unit, y: 50 * unit))
                    path.addLine(to: CGPoint(x: 21 * unit, y: 50 * unit))
                    path.closeSubpath()
                }
                .fill(Color(red: 1.0, green: 0.98, blue: 0.95))

                Path { path in
                    path.addRoundedRect(
                        in: CGRect(x: 36 * unit, y: 18 * unit, width: 8 * unit, height: 15 * unit),
                        cornerSize: CGSize(width: 1.5 * unit, height: 1.5 * unit)
                    )
                }
                .fill(Color(red: 1.0, green: 0.98, blue: 0.95).opacity(0.86))

                Circle()
                    .fill(BrandPalette.ink.opacity(0.12))
                    .frame(width: 18 * unit, height: 18 * unit)
                    .position(x: 44 * unit, y: 42 * unit)

                Circle()
                    .stroke(Color(red: 1.0, green: 0.98, blue: 0.95), lineWidth: 3 * unit)
                    .frame(width: 13 * unit, height: 13 * unit)
                    .position(x: 44 * unit, y: 42 * unit)

                Path { path in
                    path.move(to: CGPoint(x: 48.8 * unit, y: 46.8 * unit))
                    path.addLine(to: CGPoint(x: 53 * unit, y: 51 * unit))
                }
                .stroke(
                    Color(red: 1.0, green: 0.98, blue: 0.95),
                    style: StrokeStyle(lineWidth: 3 * unit, lineCap: .round)
                )
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("LedgerLens")
        .accessibilityElement(children: .ignore)
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
