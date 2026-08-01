import SwiftUI

/// User-selectable app appearance. `system` follows macOS; the others force a mode.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    /// The SwiftUI color scheme to force, or nil to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Persisted app-wide preferences (currently just appearance).
@MainActor
final class AppSettings: ObservableObject {
    @Published var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    private let defaults: UserDefaults
    private enum Key { static let appearance = "ll_appearance" }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.string(forKey: Key.appearance) ?? AppAppearance.system.rawValue
        appearance = AppAppearance(rawValue: raw) ?? .system
    }

    var colorScheme: ColorScheme? { appearance.colorScheme }
}
