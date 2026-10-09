import Foundation

/// A source of usage meters. Claude now, OpenAI in phase 2.
protocol UsageProvider {
    func fetch() async throws -> ProviderResult
}

struct ProviderResult {
    var plan: String?
    var meters: [UsageMeter]
}

enum UsageError: LocalizedError {
    case tokenMissing
    case tokenExpired
    case http(Int)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .tokenMissing: "No hay sesión de Claude Code en el Keychain"
        case .tokenExpired: "Token expirado — abre Claude Code"
        case .http(let code): "HTTP \(code)"
        case .badResponse: "Respuesta inesperada"
        }
    }
}

/// Reads the Claude Code OAuth token from the Keychain and queries the
/// subscription usage endpoint (same data as `/usage` in Claude Code).
///
/// The token is never refreshed here: refreshing rotates the refresh token
/// and would log Claude Code out. Claude Code refreshes it when you use it.
struct ClaudeUsageClient: UsageProvider {
    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    private struct Credentials: Decodable {
        struct OAuth: Decodable {
            var accessToken: String
            var expiresAt: Double?
            var subscriptionType: String?
        }
        var claudeAiOauth: OAuth
    }

    private struct Window: Decodable {
        var utilization: Double?
        var resets_at: String?
    }

    private struct Response: Decodable {
        var five_hour: Window?
        var seven_day: Window?
        var seven_day_opus: Window?
        var seven_day_sonnet: Window?
    }

    func fetch() async throws -> ProviderResult {
        let creds = try Self.readCredentials().claudeAiOauth
        if let exp = creds.expiresAt, Date(timeIntervalSince1970: exp / 1000) < .now {
            throw UsageError.tokenExpired
        }

        var req = URLRequest(url: Self.endpoint, timeoutInterval: 20)
        req.setValue("Bearer \(creds.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw UsageError.badResponse }
        if http.statusCode == 401 { throw UsageError.tokenExpired }
        guard http.statusCode == 200 else { throw UsageError.http(http.statusCode) }

        let r = try JSONDecoder().decode(Response.self, from: data)
        // Prefer the Opus weekly limit; fall back to Sonnet if that's the one the plan has.
        let modelWindow = r.seven_day_opus ?? r.seven_day_sonnet
        let modelLabel = r.seven_day_opus != nil ? "Opus" : (r.seven_day_sonnet != nil ? "Sonnet" : "Opus")

        return ProviderResult(plan: creds.subscriptionType, meters: [
            meter("five_hour", "Sesión", "clock", r.five_hour),
            meter("seven_day", "Semana", "calendar", r.seven_day),
            meter("seven_day_model", modelLabel, "sparkles", modelWindow),
        ])
    }

    private func meter(_ id: String, _ label: String, _ symbol: String, _ w: Window?) -> UsageMeter {
        UsageMeter(id: id, label: label, symbol: symbol,
                   percent: w?.utilization,
                   resetsAt: w?.resets_at.flatMap(Self.parseDate))
    }

    /// `security` is used instead of SecItemCopyMatching because the item's ACL
    /// already trusts that binary, so no Keychain prompt appears.
    private static func readCredentials() throws -> Credentials {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        p.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        try p.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0,
              let creds = try? JSONDecoder().decode(Credentials.self, from: data)
        else { throw UsageError.tokenMissing }
        return creds
    }

    /// Handles "2026-10-10T04:30:00.291978+00:00" (microseconds, which
    /// ISO8601DateFormatter doesn't parse) by dropping the fraction.
    private static func parseDate(_ s: String) -> Date? {
        let trimmed = s.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)
        return ISO8601DateFormatter().date(from: trimmed)
    }
}
