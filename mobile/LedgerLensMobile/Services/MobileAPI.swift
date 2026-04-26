import Foundation

final class MobileAPI {
    static let shared = MobileAPI()

    var baseURL: URL {
        resolvedBaseURL()
    }

    func login(email: String) async throws -> AccountSummary {
        let url = baseURL.appending(path: "/api/mobile/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email.lowercased()])

        let (data, response) = try await perform(request: request)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(AccountSummary.self, from: data)
    }

    func fetchAccountSummary(email: String) async throws -> AccountSummary {
        let url = baseURL.appending(path: "/api/account/summary")
        var request = URLRequest(url: url)
        request.setValue(email.lowercased(), forHTTPHeaderField: "x-ledgerlens-email")

        let (data, response) = try await perform(request: request)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(AccountSummary.self, from: data)
    }

    private func resolvedBaseURL() -> URL {
        if let environmentValue = ProcessInfo.processInfo.environment["LEDGERLENS_BASE_URL"],
           let environmentURL = URL(string: environmentValue) {
            return environmentURL
        }

        return URL(string: "https://ledger.dashovia.com")!
    }

    private func perform(request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .cannotFindHost {
            let message = """
            Could not reach LedgerLens at \(baseURL.absoluteString).
            Check that the deployed domain is live and reachable from this device.
            """
            throw NSError(domain: "LedgerLensMobile", code: error.errorCode, userInfo: [NSLocalizedDescriptionKey: message])
        } catch {
            throw error
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Network request failed"
            throw NSError(domain: "LedgerLensMobile", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}
