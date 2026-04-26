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
            ZStack {
                Color.clear

                ScrollView(showsIndicators: false) {
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
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Convert")
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true,
                onCompletion: handleFileSelection
            )
            .navigationDestination(item: $result) { converted in
                MobileConversionResultView(
                    result: converted,
                    tierName: authStore.account?.tierName ?? "LedgerLens",
                    onShareCSV: { shareCSV(converted) },
                    onShareJSON: { shareJSON(converted) }
                )
            }
            .sheet(item: $exportItem) { item in
                ShareSheet(items: [item.url])
            }
        }
    }

    private var isTrialExpired: Bool {
        guard let account = authStore.account else {
            return false
        }

        return account.paymentStatus != "paid" && !account.trial.isActive
    }

    private var trialEndedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Trial ended")
                .font(.title3.weight(.bold))
                .foregroundColor(BrandPalette.ink)

            Text("Your 7-day trial window has ended. Choose a paid plan on the LedgerLens web app to continue converting statements on mobile and web.")
                .foregroundColor(BrandPalette.muted)

            Link(destination: URL(string: "https://ledger.dashovia.com/pricing")!) {
                Text("View plans on the web app")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [BrandPalette.sand, BrandPalette.warning],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(BrandPalette.warning.opacity(0.22), lineWidth: 1)
        )
    }

    private var uploadCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upload statements")
                .font(.title2.weight(.bold))
                .foregroundColor(BrandPalette.ink)

            Text("Pick bank statement PDFs, add a password only if the statement is protected, and convert using your existing LedgerLens access.")
                .foregroundColor(BrandPalette.muted)

            if isTrialExpired {
                trialEndedCard
            } else {
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
                        .foregroundColor(BrandPalette.ink)
                        .tint(BrandPalette.sky)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(BrandPalette.surfaceStrong, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(BrandPalette.sky.opacity(0.12), lineWidth: 1)
                        )
                }

                if let account = authStore.account, account.maxFilesPerUpload > 1 {
                    Text("Multiple PDFs support unlocked statements only. Batch uploads are merged into one combined export.")
                        .font(.footnote)
                        .foregroundColor(BrandPalette.muted)
                }
            }

            Text("We do not store your uploaded PDFs or extracted transaction data.")
                .font(.footnote)
                .foregroundColor(BrandPalette.muted)

            if !errorMessage.isEmpty {
                StatusNotice(
                    title: isTrialExpired ? "Trial access has ended" : "Conversion couldn't start",
                    message: errorMessage,
                    tone: isTrialExpired ? .warning : .error
                )
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
            Text("Result screen")
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

                    Text("Your latest conversion opens in a dedicated review screen so the transaction table and export actions have more room.")
                        .foregroundColor(BrandPalette.muted)
                }
            } else {
                Text("After conversion, the full detected table opens on its own screen for review and export.")
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

    private func transactionTable(rows: [TransactionRow]) -> some View {
        let includesSourceFile = rows.contains { ($0.sourceFile ?? "").isEmpty == false }

        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    if includesSourceFile {
                        tableHeaderCell("File", width: 180)
                    }
                    tableHeaderCell("Date", width: 110)
                    tableHeaderCell("Description", width: 250)
                    tableHeaderCell("Debit", width: 110)
                    tableHeaderCell("Credit", width: 110)
                    tableHeaderCell("Balance", width: 120)
                }

                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    HStack(spacing: 0) {
                        if includesSourceFile {
                            tableBodyCell(row.sourceFile ?? "-", width: 180, alignment: .leading, isEmphasized: false)
                        }
                        tableBodyCell(row.date, width: 110, alignment: .leading, isEmphasized: false)
                        tableBodyCell(row.description, width: 250, alignment: .leading, isEmphasized: true)
                        tableBodyCell(row.debit.isEmpty ? "-" : row.debit, width: 110, alignment: .trailing, isEmphasized: false)
                        tableBodyCell(row.credit.isEmpty ? "-" : row.credit, width: 110, alignment: .trailing, isEmphasized: false)
                        tableBodyCell(row.balance.isEmpty ? "-" : row.balance, width: 120, alignment: .trailing, isEmphasized: false)
                    }
                    .background(index.isMultiple(of: 2) ? BrandPalette.surfaceStrong : Color.white.opacity(0.72))
                }
            }
        }
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(BrandPalette.sky.opacity(0.10), lineWidth: 1)
        )
    }

    private func tableHeaderCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundColor(BrandPalette.ink)
            .textCase(.uppercase)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(BrandPalette.sky.opacity(0.10))
    }

    private func tableBodyCell(
        _ value: String,
        width: CGFloat,
        alignment: Alignment,
        isEmphasized: Bool
    ) -> some View {
        Text(value)
            .font(isEmphasized ? .subheadline.weight(.semibold) : .subheadline)
            .foregroundColor(isEmphasized ? BrandPalette.ink : BrandPalette.muted)
            .lineLimit(3)
            .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
            .frame(width: width, alignment: alignment)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
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
            } else if pdfs.count > 1 && !password.isEmpty {
                errorMessage = "Multiple PDFs support unlocked statements only. Clear the password and upload unlocked PDFs."
                selectedDocuments = pdfs
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

        if selectedDocuments.count > 1 && !password.isEmpty {
            errorMessage = "Multiple PDFs support unlocked statements only. Clear the password and upload unlocked PDFs."
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

private struct MobileConversionResultView: View {
    let result: ConversionResult
    let tierName: String
    let onShareCSV: () -> Void
    let onShareJSON: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Detected transactions")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(BrandPalette.ink)

                    Text("Review the combined conversion output in one clean place before you export or share it.")
                        .foregroundColor(BrandPalette.muted)

                    HStack(spacing: 12) {
                        summaryBadge(value: "\(result.rows.count)", label: "rows")
                        summaryBadge(value: "\(result.pageCount)", label: "pages")
                        summaryBadge(value: tierName, label: "tier")
                    }

                    usageSummary
                }
                .padding(20)
                .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Export")
                        .font(.headline)
                        .foregroundColor(BrandPalette.ink)

                    HStack(spacing: 12) {
                        Button("Share CSV") {
                            onShareCSV()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(BrandPalette.sky)

                        if result.exportFormats.contains("json") {
                            Button("Share JSON") {
                                onShareJSON()
                            }
                            .buttonStyle(.bordered)
                            .tint(BrandPalette.lilac)
                        }
                    }

                    Text(result.rows.contains { ($0.sourceFile ?? "").isEmpty == false }
                         ? "Multiple unlocked PDFs were combined into one export. The File column keeps each row traceable."
                         : "This conversion came from a single statement and is ready to export.")
                        .font(.footnote)
                        .foregroundColor(BrandPalette.muted)
                }
                .padding(20)
                .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Table preview")
                        .font(.headline)
                        .foregroundColor(BrandPalette.ink)

                    transactionTable(rows: result.rows)
                }
                .padding(20)
                .background(BrandPalette.surface, in: RoundedRectangle(cornerRadius: 24))
            }
            .padding()
            .padding(.bottom, 20)
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var usageSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            if result.trial.isActive {
                Text("\(result.trial.pdfsUsed ?? 0)/\(result.trial.pdfLimit ?? 5) PDFs used • \(result.trial.pagesUsed ?? 0)/\(result.trial.pageLimit ?? 50) pages used")
                    .foregroundColor(BrandPalette.muted)
            } else if let used = result.pagesUsedThisMonth, let remaining = result.pagesRemainingThisMonth {
                Text("\(used) pages used this month • \(remaining) pages remaining")
                    .foregroundColor(BrandPalette.muted)
            }
        }
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

    private func transactionTable(rows: [TransactionRow]) -> some View {
        let includesSourceFile = rows.contains { ($0.sourceFile ?? "").isEmpty == false }

        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    if includesSourceFile {
                        tableHeaderCell("File", width: 180)
                    }
                    tableHeaderCell("Date", width: 110)
                    tableHeaderCell("Description", width: 250)
                    tableHeaderCell("Debit", width: 110)
                    tableHeaderCell("Credit", width: 110)
                    tableHeaderCell("Balance", width: 120)
                }

                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    HStack(spacing: 0) {
                        if includesSourceFile {
                            tableBodyCell(row.sourceFile ?? "-", width: 180, alignment: .leading, isEmphasized: false)
                        }
                        tableBodyCell(row.date, width: 110, alignment: .leading, isEmphasized: false)
                        tableBodyCell(row.description, width: 250, alignment: .leading, isEmphasized: true)
                        tableBodyCell(row.debit.isEmpty ? "-" : row.debit, width: 110, alignment: .trailing, isEmphasized: false)
                        tableBodyCell(row.credit.isEmpty ? "-" : row.credit, width: 110, alignment: .trailing, isEmphasized: false)
                        tableBodyCell(row.balance.isEmpty ? "-" : row.balance, width: 120, alignment: .trailing, isEmphasized: false)
                    }
                    .background(index.isMultiple(of: 2) ? BrandPalette.surfaceStrong : Color.white.opacity(0.72))
                }
            }
        }
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(BrandPalette.sky.opacity(0.10), lineWidth: 1)
        )
    }

    private func tableHeaderCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundColor(BrandPalette.ink)
            .textCase(.uppercase)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(BrandPalette.sky.opacity(0.10))
    }

    private func tableBodyCell(
        _ value: String,
        width: CGFloat,
        alignment: Alignment,
        isEmphasized: Bool
    ) -> some View {
        Text(value)
            .font(isEmphasized ? .subheadline.weight(.semibold) : .subheadline)
            .foregroundColor(isEmphasized ? BrandPalette.ink : BrandPalette.muted)
            .lineLimit(3)
            .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
            .frame(width: width, alignment: alignment)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
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
