import Foundation
import SwiftUI
import AppKit

/// Tracks a **usage-based free trial** (first N statements free) and lifetime/subscription Pro
/// entitlement, persisted in `UserDefaults`.
///
/// Trial: the first `freeStatements` statements convert for free — no clock. Pro: unlocked by
/// activating a Polar license key (any plan — monthly, yearly, or lifetime issues one),
/// validated once over the network then cached locally so the app keeps working offline.
/// Statement processing is always local regardless of license state.
@MainActor
final class LicenseStore: ObservableObject {
    let freeStatements = 5

    @Published var showSettings = false
    @Published var showUpgrade = false

    @Published private(set) var isPro: Bool
    @Published private(set) var statementsUsed: Int

    // Activation UI state
    @Published var licenseKeyInput: String = ""
    @Published var isActivating = false
    @Published var activationError: String?

    private let defaults: UserDefaults
    private enum Key {
        static let isPro = "ll_is_pro"
        static let licenseKey = "ll_license_key"
        static let statementsUsed = "ll_statements_used"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isPro = defaults.bool(forKey: Key.isPro)
        statementsUsed = defaults.integer(forKey: Key.statementsUsed)
        licenseKeyInput = defaults.string(forKey: Key.licenseKey) ?? ""
    }

    // MARK: - Derived state

    var statementsRemaining: Int { max(0, freeStatements - statementsUsed) }
    var isTrialActive: Bool { statementsRemaining > 0 }
    var canConvert: Bool { isPro || statementsRemaining > 0 }

    var statusText: String {
        if isPro { return "Pro" }
        let r = statementsRemaining
        return r > 0 ? "\(r) of \(freeStatements) free left" : "Free statements used"
    }

    /// Short label for the sidebar pill.
    var pillText: String {
        if isPro { return "PRO" }
        return statementsRemaining > 0 ? "FREE · \(statementsRemaining) LEFT" : "UPGRADE"
    }

    // MARK: - Actions

    /// Counts converted statements against the free allowance (no-op once Pro).
    func registerConversion(statements: Int) {
        guard !isPro else { return }
        statementsUsed += max(0, statements)
        defaults.set(statementsUsed, forKey: Key.statementsUsed)
        objectWillChange.send()
    }

    func openCheckout(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    func activate() {
        let key = licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            activationError = "Enter your license key."
            return
        }
        isActivating = true
        activationError = nil

        Task {
            do {
                let result = try await PolarClient.validate(licenseKey: key)
                if result.valid {
                    unlockPro(with: key)
                    showUpgrade = false
                } else {
                    activationError = result.message ?? "That license key isn't valid."
                }
            } catch {
                activationError = error.localizedDescription
            }
            isActivating = false
        }
    }

    private func unlockPro(with key: String) {
        isPro = true
        defaults.set(true, forKey: Key.isPro)
        defaults.set(key, forKey: Key.licenseKey)
    }

    #if DEBUG
    func resetForTesting() {
        defaults.removeObject(forKey: Key.isPro)
        defaults.removeObject(forKey: Key.licenseKey)
        defaults.removeObject(forKey: Key.statementsUsed)
    }
    #endif
}
