import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct MobileConverterView: View {
    @EnvironmentObject private var authStore: MobileAuthStore
    @State private var selectedDocuments: [PickedPDF] = []
    @State private var password = ""
    @State private var result: ConversionResult?
    @State private var errorMessage = ""
    @State private var isPickerPresented = false
    @State private var isConverting = false
    @State private var exportItem: SharedExport?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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

                    uploadCard
                    selectedFilesCard
                    resultCard
                }
                .padding()
            }
            .navigationTitle("Convert")
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true,
                onCompletion: handleFileSelection
            )
            .sheet(item: $exportItem) { item in
                ShareSheet(items: [item.url])
            }
        }
    }

    private var uploadCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upload statements")
                .font(.title2.weight(.bold))
                .foregroundColor(BrandPalette.ink)

            Text("Pick bank statement PDFs, add a password only if the statement is protected, and convert using your existing LedgerLens access.")
                .foregroundColor(BrandPalette.muted)

            HStack(spacing: 12) {
                Button {
                    isPickerPresented = true
                } label: {
                    Label("Choose PDFs", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(BrandPalette.sky)

                Button {
                    Task { await convertStatements() }
                } label: {
                    Text(isConverting ? "Converting..." : "Convert")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(BrandPalette.aqua)
                .disabled(isConverting || selectedDocuments.isEmpty || authStore.account == nil)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Password for protected PDFs")
                    .font(.headline)
                    .foregroundColor(BrandPalette.ink)

                SecureField("Leave blank if the PDF is unlocked", text: $password)
                    .padding()
                    .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
            }

            Text("We do not store your uploaded PDFs or extracted transaction data.")
                .font(.footnote)
                .foregroundColor(BrandPalette.muted)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(20)
        .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private var selectedFilesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Selected files")
                    .font(.headline)
                    .foregroundColor(BrandPalette.ink)

                Spacer()

                Text("\(selectedDocuments.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(BrandPalette.sky)
            }

            if selectedDocuments.isEmpty {
                Text("No PDFs selected yet.")
                    .foregroundColor(BrandPalette.muted)
            } else {
                ForEach(selectedDocuments) { document in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "doc.richtext")
                            .foregroundColor(BrandPalette.sky)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.fileName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(BrandPalette.ink)

                            if let fileSizeLabel = document.fileSizeLabel {
                                Text(fileSizeLabel)
                                    .font(.footnote)
                                    .foregroundColor(BrandPalette.muted)
                            }
                        }

                        Spacer()

                        Button {
                            selectedDocuments.removeAll { $0.id == document.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(.title2.weight(.bold))
                .foregroundColor(BrandPalette.ink)

            if let result {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        summaryBadge(value: "\(result.rows.count)", label: "rows")
                        summaryBadge(value: "\(result.pageCount)", label: "pages")
                        summaryBadge(value: result.queuePriority.capitalized, label: "priority")
                    }

                    usageSummary(result: result)

                    exportButtons(result: result)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detected transactions")
                            .font(.headline)
                            .foregroundColor(BrandPalette.ink)

                        ForEach(Array(result.rows.prefix(12))) { row in
                            transactionCard(row: row)
                        }

                        if result.rows.count > 12 {
                            Text("Showing the first 12 rows. Export to open the full result.")
                                .font(.footnote)
                                .foregroundColor(BrandPalette.muted)
                        }
                    }
                }
            } else {
                Text("Your converted rows will appear here after a successful upload.")
                    .foregroundColor(BrandPalette.muted)
            }
        }
        .padding(20)
        .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private func summaryBadge(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(BrandPalette.ink)

            Text(label.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(BrandPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
    }

    private func usageSummary(result: ConversionResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if result.trial.isActive {
                Text("Trial usage")
                    .font(.headline)
                    .foregroundColor(BrandPalette.ink)

                Text(
                    "\(result.trial.pdfsUsed ?? 0)/\(result.trial.pdfLimit ?? 5) PDFs used • \(result.trial.pagesUsed ?? 0)/\(result.trial.pageLimit ?? 50) pages used"
                )
                .foregroundColor(BrandPalette.muted)
            } else if let used = result.pagesUsedThisMonth, let remaining = result.pagesRemainingThisMonth {
                Text("Plan usage")
                    .font(.headline)
                    .foregroundColor(BrandPalette.ink)

                Text("\(used) pages used this month • \(remaining) pages remaining")
                    .foregroundColor(BrandPalette.muted)
            }
        }
    }

    private func exportButtons(result: ConversionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export")
                .font(.headline)
                .foregroundColor(BrandPalette.ink)

            HStack(spacing: 12) {
                Button("Share CSV") {
                    shareCSV(result)
                }
                .buttonStyle(.borderedProminent)
                .tint(BrandPalette.sky)

                if result.exportFormats.contains("json") {
                    Button("Share JSON") {
                        shareJSON(result)
                    }
                    .buttonStyle(.bordered)
                    .tint(BrandPalette.lilac)
                }
            }

            if result.exportFormats.contains("xlsx") {
                Text("XLSX export is still best on the web app. Mobile export currently shares CSV, which opens cleanly in Excel, Numbers, and Sheets.")
                    .font(.footnote)
                    .foregroundColor(BrandPalette.muted)
            }
        }
    }

    private func transactionCard(row: TransactionRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let sourceFile = row.sourceFile, !sourceFile.isEmpty {
                Text(sourceFile)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(BrandPalette.sky)
            }

            Text(row.description)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(BrandPalette.ink)

            Text(row.date)
                .font(.footnote)
                .foregroundColor(BrandPalette.muted)

            HStack(spacing: 12) {
                amountPill(label: "Debit", value: row.debit)
                amountPill(label: "Credit", value: row.credit)
                amountPill(label: "Balance", value: row.balance)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
    }

    private func amountPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(BrandPalette.muted)
            Text(value.isEmpty ? "-" : value)
                .font(.footnote.weight(.semibold))
                .foregroundColor(BrandPalette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let account = authStore.account else {
                errorMessage = "Please log in again to refresh your LedgerLens account."
                return
            }

            let pdfs = urls
                .filter { $0.pathExtension.lowercased() == "pdf" }
                .map(PickedPDF.init)

            if pdfs.isEmpty {
                errorMessage = "Choose one or more PDF bank statements."
                return
            }

            if pdfs.count > account.maxFilesPerUpload {
                errorMessage = "Your \(account.tierName) plan supports up to \(account.maxFilesPerUpload) file(s) per upload."
                selectedDocuments = Array(pdfs.prefix(account.maxFilesPerUpload))
            } else {
                errorMessage = ""
                selectedDocuments = pdfs
            }

            self.result = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func convertStatements() async {
        guard let account = authStore.account else {
            errorMessage = "Log in to continue."
            return
        }

        guard !selectedDocuments.isEmpty else {
            errorMessage = "Choose at least one PDF statement first."
            return
        }

        isConverting = true
        errorMessage = ""

        do {
            let uploads = try selectedDocuments.map { document in
                (fileName: document.fileName, data: try document.readData())
            }

            let converted = try await MobileAPI.shared.convert(
                email: account.email,
                password: password,
                documents: uploads
            )

            result = converted
            password = ""
            await authStore.refresh()
        } catch {
            errorMessage = error.localizedDescription
        }

        isConverting = false
    }

    private func shareCSV(_ result: ConversionResult) {
        do {
            let columns = csvColumns(for: result.rows)
            let csvRows = [columns.joined(separator: ",")] + result.rows.map { row in
                columns.map { csvValue(for: row, column: $0) }.joined(separator: ",")
            }

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(result.fileStem).csv")
            try csvRows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            exportItem = SharedExport(url: url)
        } catch {
            errorMessage = "Could not prepare the CSV export."
        }
    }

    private func shareJSON(_ result: ConversionResult) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(result.rows)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(result.fileStem).json")
            try data.write(to: url, options: .atomic)
            exportItem = SharedExport(url: url)
        } catch {
            errorMessage = "Could not prepare the JSON export."
        }
    }

    private func csvColumns(for rows: [TransactionRow]) -> [String] {
        rows.contains { ($0.sourceFile ?? "").isEmpty == false }
            ? ["sourceFile", "date", "description", "debit", "credit", "balance"]
            : ["date", "description", "debit", "credit", "balance"]
    }

    private func csvValue(for row: TransactionRow, column: String) -> String {
        let rawValue: String

        switch column {
        case "sourceFile":
            rawValue = row.sourceFile ?? ""
        case "date":
            rawValue = row.date
        case "description":
            rawValue = row.description
        case "debit":
            rawValue = row.debit
        case "credit":
            rawValue = row.credit
        case "balance":
            rawValue = row.balance
        default:
            rawValue = ""
        }

        return "\"\(rawValue.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}

private struct PickedPDF: Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    let fileSizeLabel: String?

    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent

        if let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
           let fileSize = values.fileSize {
            self.fileSizeLabel = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
        } else {
            self.fileSizeLabel = nil
        }
    }

    func readData() throws -> Data {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try Data(contentsOf: url)
    }
}

private struct SharedExport: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
