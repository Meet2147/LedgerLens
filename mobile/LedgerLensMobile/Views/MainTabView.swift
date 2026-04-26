import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            MobileConverterView()
                .tabItem {
                    Label("Convert", systemImage: "doc.viewfinder")
                }

            MobileAccountView()
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
        }
        .tint(BrandPalette.sky)
    }
}
