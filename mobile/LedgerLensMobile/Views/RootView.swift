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

            if authStore.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(.light)
    }
}
