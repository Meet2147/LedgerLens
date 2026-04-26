import SwiftUI

@main
struct LedgerLensMobileApp: App {
    @StateObject private var authStore = MobileAuthStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authStore)
        }
    }
}
