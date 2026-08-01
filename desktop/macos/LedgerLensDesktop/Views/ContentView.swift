import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var model: ConverterModel
    @EnvironmentObject private var license: LicenseStore
    @EnvironmentObject private var settings: AppSettings

    private var settingsBinding: Binding<Bool> {
        Binding(
            get: { license.showSettings || license.showUpgrade },
            set: { newValue in
                if !newValue { license.showSettings = false; license.showUpgrade = false }
            }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            InputPanel()
                .frame(width: 360)

            ResultsPanel()
                .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 940, minHeight: 600)
        .background(BrandPalette.base.ignoresSafeArea())
        // Note: .fileImporter lives on InputPanel and .fileExporter on ResultsPanel — keeping
        // each presentation modifier on a *separate* view avoids SwiftUI's known conflict
        // where stacking several on one view stops some from presenting.
        .sheet(isPresented: settingsBinding) {
            SettingsView()
                .environmentObject(license)
                .environmentObject(settings)
        }
        .onAppear {
            // Optional automation/testing hook: point LEDGERLENS_AUTOLOAD_PDF at a file to
            // load and convert it on launch. Unset in normal use.
            if let path = ProcessInfo.processInfo.environment["LEDGERLENS_AUTOLOAD_PDF"] {
                model.addFiles([URL(fileURLWithPath: path)])
                model.convert()
            }
        }
    }
}

/// The brand lockup: the app logo, rendered from the shared asset.
struct BrandMark: View {
    var size: CGFloat = 38

    var body: some View {
        Image("BrandLogo")
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: BrandPalette.accent.opacity(0.35), radius: 6, x: 3, y: 3)
    }
}

/// A small raised pill used for status chips.
struct NeuPill: View {
    let systemImage: String
    let text: String
    var tint: Color = BrandPalette.success

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 10.5, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .neuRaised(20)
    }
}

#Preview {
    ContentView().environmentObject(ConverterModel())
}
