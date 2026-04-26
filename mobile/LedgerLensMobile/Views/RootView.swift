import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authStore: MobileAuthStore

    var body: some View {
        Group {
            if authStore.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .background(
            LinearGradient(
                colors: [.white, BrandPalette.background, BrandPalette.sky.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
