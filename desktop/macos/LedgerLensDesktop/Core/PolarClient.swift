import Foundation

/// Minimal client for Polar's public license-key validation endpoint.
///
/// This is the *only* network call the app makes, and it sends only the license key the user
/// typed plus the public organization id — never any statement data. Validation is an
/// unauthenticated (public) endpoint, so no secret token ships in the app.
enum PolarClient {

    struct ValidationResult {
        let valid: Bool
        let message: String?
    }

    enum PolarError: LocalizedError {
        case notConfigured
        case network(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Polar isn't configured yet. Add your organization id in PolarConfig.swift."
            case .network(let message):
                return message
            }
        }
    }

    /// Validates a license key against Polar. Returns whether it's currently valid
    /// (granted / not disabled / not expired).
    static func validate(licenseKey: String) async throws -> ValidationResult {
        let key = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            return ValidationResult(valid: false, message: "Enter your license key.")
        }
        guard !PolarConfig.organizationId.hasPrefix("REPLACE_") else {
            throw PolarError.notConfigured
        }

        let url = PolarConfig.apiBase.appending(path: "/v1/customer-portal/license-keys/validate")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "key": key,
            "organization_id": PolarConfig.organizationId
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PolarError.network("No response from Polar.")
        }

        // A 200 means the key exists and validated; 4xx means invalid/unknown key.
        if http.statusCode == 200 {
            // Optionally inspect the returned status field.
            if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = object["status"] as? String {
                let ok = status.lowercased() == "granted"
                return ValidationResult(valid: ok, message: ok ? nil : "This license is \(status).")
            }
            return ValidationResult(valid: true, message: nil)
        }

        if http.statusCode == 404 || http.statusCode == 403 {
            return ValidationResult(valid: false, message: "That license key wasn't recognized.")
        }

        let body = String(data: data, encoding: .utf8) ?? ""
        throw PolarError.network("Polar returned \(http.statusCode). \(body)")
    }
}
