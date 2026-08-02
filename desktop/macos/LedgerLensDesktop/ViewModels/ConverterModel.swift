import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Drives the converter screen: holds the selected PDFs and password, runs conversion off the
/// main thread, and handles import/export. All work is local.
///
/// File dialogs use AppKit `NSOpenPanel`/`NSSavePanel` presented as **window sheets**
/// (`beginSheetModal`). This is the reliable path on a borderless window — SwiftUI's
/// `.fileImporter`/`.fileExporter` failed to re-present on repeated use and didn't enforce the
/// file extension (exports came out without `.csv`/`.xlsx`).
@MainActor
final class ConverterModel: ObservableObject {
    @Published var selectedFiles: [URL] = []
    @Published var password: String = ""
    @Published var isConverting = false
    @Published var result: ConversionResult?
    @Published var errorMessage: String?

    /// Injected so gated features (Convert) can check entitlement without tight coupling.
    weak var license: LicenseStore?

    var hasFiles: Bool { !selectedFiles.isEmpty }

    // MARK: - Window helper

    /// The app's main window, used to attach panels as sheets.
    private var hostWindow: NSWindow? {
        NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first { $0.isVisible }
    }

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

    /// Opens the system file picker for PDFs.
    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]
        panel.prompt = "Add"
        panel.message = "Choose one or more PDF bank statements"

        NSApp.activate(ignoringOtherApps: true)

        let completion: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .OK else { return }
            self?.addFiles(panel.urls)
        }

        if let window = hostWindow {
            panel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            panel.begin(completionHandler: completion)
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
        save(data: data, fileStem: result.fileStem, ext: "csv", type: .commaSeparatedText)
    }

    func exportXLSX() {
        guard let result else { return }
        let data = SpreadsheetExporter.xlsx(rows: result.rows, includeSourceFile: result.isBatch)
        let xlsxType = UTType(filenameExtension: "xlsx") ?? .data
        save(data: data, fileStem: result.fileStem, ext: "xlsx", type: xlsxType)
    }

    /// Presents a save panel (as a window sheet) with the extension baked into the default name
    /// and enforced by `allowedContentTypes`, then writes the data to the chosen URL.
    private func save(data: Data, fileStem: String, ext: String, type: UTType) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(fileStem).\(ext)"
        panel.allowedContentTypes = [type]
        panel.isExtensionHidden = false
        panel.canCreateDirectories = true

        NSApp.activate(ignoringOtherApps: true)

        let completion: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                self?.errorMessage = "Couldn't save the file: \(error.localizedDescription)"
            }
        }

        if let window = hostWindow {
            panel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            panel.begin(completionHandler: completion)
        }
    }
}
