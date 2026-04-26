import SwiftUI

struct MobileConverterView: View {
    @EnvironmentObject private var authStore: MobileAuthStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mobile converter")
                        .font(.title2.weight(.bold))
                        .foregroundColor(BrandPalette.ink)

                    Text("This SwiftUI version is scaffolded to use the same LedgerLens backend and the same account tier. Next step is wiring a document picker and multipart upload to `/api/convert`.")
                        .foregroundColor(BrandPalette.muted)

                    if let account = authStore.account {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your current access")
                                .font(.headline)
                            Text("Tier: \(account.tierName)")
                            Text("Files per upload: \(account.maxFilesPerUpload)")
                            Text("Exports: \(account.exportFormats.joined(separator: ", ").uppercased())")
                        }
                        .padding(20)
                        .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Planned mobile flow")
                            .font(.headline)
                        Text("1. Pick PDF documents")
                        Text("2. Enter statement password if needed")
                        Text("3. Upload with your LedgerLens email identity")
                        Text("4. Preview rows")
                        Text("5. Export to CSV, XLSX, or JSON based on your tier")
                    }
                    .padding(20)
                    .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
                }
                .padding()
            }
            .navigationTitle("Convert")
        }
    }
}
