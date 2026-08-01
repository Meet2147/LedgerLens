import SwiftUI
import UniformTypeIdentifiers

/// Sidebar, styled as neumorphic controls floating on the shared base surface.
struct InputPanel: View {
    @EnvironmentObject private var model: ConverterModel
    @EnvironmentObject private var license: LicenseStore
    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    section(number: "1", title: "Add statements") {
                        dropZone
                        if model.hasFiles { fileList }
                    }

                    section(number: "2", title: "Password", subtitle: "optional") {
                        SecureField("PDF password", text: $model.password)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundStyle(BrandPalette.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .neuInset(11)
                        Text("Only needed for locked PDFs.")
                            .font(.system(size: 10.5))
                            .foregroundStyle(BrandPalette.textFaint)
                    }

                    if let error = model.errorMessage {
                        errorBanner(error)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 22)
            }

            convertBar
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BrandPalette.base)
        .fileImporter(
            isPresented: $model.showFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true,
            onCompletion: model.handleImport
        )
    }

    // MARK: - Header

    private var brandHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                BrandMark(size: 40)
                VStack(alignment: .leading, spacing: 1) {
                    Text("LedgerLens")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(BrandPalette.textPrimary)
                    Text("Statements → spreadsheets")
                        .font(.system(size: 11.5))
                        .foregroundStyle(BrandPalette.textSecondary)
                }
                Spacer()
                Button { license.showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(BrandPalette.textSecondary)
                        .frame(width: 30, height: 30)
                        .neuRaised(15)
                }
                .buttonStyle(.plain)
                .help("Settings & Upgrade")
            }
            HStack(spacing: 8) {
                NeuPill(systemImage: "lock.shield.fill", text: "100% ON-DEVICE")
                licenseStatusPill
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 42) // clear traffic lights (hidden title bar)
        .padding(.bottom, 8)
    }

    /// Tappable trial/Pro status chip that opens the upgrade sheet.
    private var licenseStatusPill: some View {
        Button {
            if license.isPro { license.showSettings = true } else { license.showUpgrade = true }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: license.isPro ? "crown.fill" : (license.isTrialActive ? "gift.fill" : "bolt.fill"))
                    .font(.system(size: 10, weight: .semibold))
                Text(license.pillText)
                    .font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundStyle(license.isPro ? BrandPalette.credit : BrandPalette.accent)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .neuRaised(20)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section scaffold

    private func section<Content: View>(
        number: String,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 9) {
                Text(number)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandPalette.accent)
                    .frame(width: 22, height: 22)
                    .neuRaised(11)
                Text(title.uppercased())
                    .font(.system(size: 11.5, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(BrandPalette.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10.5))
                        .foregroundStyle(BrandPalette.textFaint)
                }
            }
            content()
        }
    }

    // MARK: - Drop zone (carved well)

    private var dropZone: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 26))
                .foregroundStyle(isDropTargeted ? BrandPalette.accent : BrandPalette.textSecondary)
            Text("Drop PDF statements")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(BrandPalette.textPrimary)
            Button("Browse files…") { model.presentOpenPanel() }
                .buttonStyle(NeuButtonStyle(radius: 10, tint: BrandPalette.accent))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .neuInset(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isDropTargeted ? BrandPalette.accent.opacity(0.7) : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [7, 6])
                )
        )
        .animation(.easeOut(duration: 0.12), value: isDropTargeted)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { handleDrop($0) }
    }

    private var fileList: some View {
        VStack(spacing: 9) {
            ForEach(model.selectedFiles, id: \.self) { url in
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(BrandPalette.accent)
                    Text(url.lastPathComponent)
                        .font(.system(size: 12))
                        .foregroundStyle(BrandPalette.textPrimary)
                        .lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button {
                        model.removeFile(url)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(BrandPalette.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .neuRaised(11)
            }

            Button(action: { model.reset() }) {
                Text("Clear all")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(BrandPalette.debit)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 2)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(BrandPalette.debit)
            Text(message)
                .font(.system(size: 11.5))
                .foregroundStyle(BrandPalette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neuInset(12)
    }

    // MARK: - Convert bar

    private var convertBar: some View {
        Button(action: { model.convert() }) {
            HStack(spacing: 8) {
                if model.isConverting {
                    ProgressView().controlSize(.small).tint(.white)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(model.isConverting ? "Converting…" : "Convert")
                    .font(.system(size: 14.5, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(model.hasFiles && !model.isConverting
                          ? AnyShapeStyle(BrandPalette.brandGradient)
                          : AnyShapeStyle(BrandPalette.textFaint))
                    .shadow(color: (model.hasFiles ? BrandPalette.accent : .clear).opacity(0.5), radius: 8, x: 4, y: 4)
                    .shadow(color: BrandPalette.lightShadow.opacity(0.8), radius: 6, x: -4, y: -4)
            )
        }
        .buttonStyle(.plain)
        .disabled(!model.hasFiles || model.isConverting)
        .padding(22)
    }

    // MARK: - Drop handling

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        let group = DispatchGroup()
        var urls: [URL] = []
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            handled = true
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                } else if let url = item as? URL {
                    urls.append(url)
                }
            }
        }
        group.notify(queue: .main) { model.addFiles(urls) }
        return handled
    }
}
