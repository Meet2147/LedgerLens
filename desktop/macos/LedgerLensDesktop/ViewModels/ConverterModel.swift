import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// A tiny FileDocument wrapper so exports go through SwiftUI's `.fileExporter`, which presents
/// reliably as a window-attached sheet (unlike `NSSavePanel.runModal()` on a borderless window).
struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// Drives the converter screen: holds the selected PDFs and password, runs conversion off the
/// main thread, and coordinates import/export via SwiftUI file dialogs. All work is local.
@MainActor
final class ConverterModel: ObservableObject {
    @Published var selectedFiles: [URL] = []
    @Published var password: String = ""
    @Published var isConverting = false
    @Published var result: ConversionResult?
    @Published var errorMessage: String?

    // File-dialog coordination (bound to `.fileImporter` / `.fileExporter` in ContentView).
    @Published var showFileImporter = false
    @Published var showExporter = false
    private(set) var exportDocument = ExportDocument(data: Data())
    private(set) var exportContentType: UTType = .commaSeparatedText
    private(set) var exportFilename = "statement"

    /// Injected so gated features (Convert) can check entitlement without tight coupling.
    weak var license: LicenseStore?

    var hasFiles: Bool { !selectedFiles.isEmpty }

    // MARK: - File selection

    func addFiles(_ urls: [URL]) {
        var added = false
        for url in urls where url.pathExtension.lowercased() == "pdf" {
            if !selectedFiles.contains(url) {
                selectedFiles.append(url)
                added = true
            }
        }
        if added { errorMessage = nil }
    }

    func removeFile(_ url: URL) {
        selectedFiles.removeAll { $0 == url }
    }

    func reset() {
        selectedFiles = []
        password = ""
        result = nil
        errorMessage = nil
    }

    /// Opens the system file picker (via `.fileImporter`).
    func presentOpenPanel() {
        showFileImporter = true
    }

    func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            addFiles(urls)
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Conversion

    func convert() {
        guard hasFiles else {
            errorMessage = "Add at least one PDF bank statement first."
            return
        }

        // Gate on trial/Pro entitlement (first N statements free).
        if let license, !license.canConvert {
            errorMessage = "You've used your \(license.freeStatements) free statements. Upgrade to keep converting."
            license.showUpgrade = true
            return
        }

        isConverting = true
        errorMessage = nil
        result = nil

        let files = selectedFiles
        let pw = password

        Task {
            do {
                let converted = try await Task.detached(priority: .userInitiated) {
                    var scoped: [URL] = []
                    for url in files where url.startAccessingSecurityScopedResource() {
                        scoped.append(url)
                    }
                    defer { scoped.forEach { $0.stopAccessingSecurityScopedResource() } }
                    return try StatementConverter.convert(fileURLs: files, password: pw)
                }.value

                self.result = converted
                self.license?.registerConversion(statements: converted.sourceFiles.count)
            } catch {
                self.errorMessage = error.localizedDescription
                self.result = nil
            }
            self.isConverting = false
        }
    }

    // MARK: - Export

    func exportCSV() {
        guard let result else { return }
        let data = SpreadsheetExporter.csv(rows: result.rows, includeSourceFile: result.isBatch)
        presentExport(data: data, type: .commaSeparatedText, filename: result.fileStem)
    }

    func exportXLSX() {
        guard let result else { return }
        let data = SpreadsheetExporter.xlsx(rows: result.rows, includeSourceFile: result.isBatch)
        let xlsxType = UTType(filenameExtension: "xlsx") ?? .data
        presentExport(data: data, type: xlsxType, filename: result.fileStem)
    }

    private func presentExport(data: Data, type: UTType, filename: String) {
        exportDocument = ExportDocument(data: data)
        exportContentType = type
        exportFilename = filename
        showExporter = true
    }

    func handleExport(_ result: Result<URL, Error>) {
        if case .failure(let error) = result {
            // Cancellation surfaces as a benign error; ignore user cancels.
            if (error as NSError).code != NSUserCancelledError {
                errorMessage = "Couldn't save the file: \(error.localizedDescription)"
            }
        }
    }
}
