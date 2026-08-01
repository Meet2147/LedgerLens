import SwiftUI

@main
struct LedgerLensDesktopApp: App {
    @StateObject private var model = ConverterModel()
    @StateObject private var license = LicenseStore()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .environmentObject(license)
                .environmentObject(settings)
                .frame(minWidth: 960, minHeight: 620)
                .preferredColorScheme(settings.colorScheme)
                .onAppear { model.license = license }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1200, height: 740)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Statements…") { model.presentOpenPanel() }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .saveItem) {
                Button("Export CSV…") { model.exportCSV() }
                    .keyboardShortcut("e", modifiers: .command)
                    .disabled(model.result == nil)
                Button("Export XLSX…") { model.exportXLSX() }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
                    .disabled(model.result == nil)
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { license.showSettings = true }
                    .keyboardShortcut(",", modifiers: .command)
                Button("Upgrade to Pro…") { license.showUpgrade = true }
            }
            CommandGroup(after: .toolbar) {
                Picker("Appearance", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { Text($0.label).tag($0) }
                }
            }
        }
    }
}
